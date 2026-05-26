package repository

import (
	"context"
	"hash/crc32"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/yourname/koreanapp-backend/internal/model"
)

var palette = []string{"#99B7F5", "#267F53", "#F5793B", "#F296BD", "#FCCA59"}

// identityColor returns a consistent palette color for a given user ID.
func identityColor(userID string) string {
	h := crc32.ChecksumIEEE([]byte(userID))
	return palette[h%uint32(len(palette))]
}

type TeacherRepository struct {
	pool *pgxpool.Pool
}

func NewTeacherRepository(pool *pgxpool.Pool) *TeacherRepository {
	return &TeacherRepository{pool: pool}
}

func (r *TeacherRepository) GetDashboard(ctx context.Context, teacherID string) (*model.TeacherDashboard, error) {
	var d model.TeacherDashboard

	// Stats: active today, total students, avg accuracy, decks assigned
	err := r.pool.QueryRow(ctx, `
		SELECT
			COUNT(DISTINCT gm.user_id) AS total_students,
			COUNT(DISTINCT CASE WHEN u.last_active = CURRENT_DATE THEN gm.user_id END) AS active_today,
			COALESCE((
				SELECT AVG(
					CASE WHEN sub.total > 0
						THEN sub.mastered::float * 100 / sub.total
						ELSE 0 END
				)::int
				FROM (
					SELECT sp.user_id,
						COUNT(*) FILTER (WHERE sp.interval_days >= 7) AS mastered,
						COUNT(*) AS total
					FROM srs_progress sp
					WHERE sp.user_id IN (
						SELECT DISTINCT gm2.user_id
						FROM group_members gm2
						JOIN groups g2 ON g2.id = gm2.group_id
						WHERE g2.created_by = $1 AND gm2.user_id != $1
					)
					GROUP BY sp.user_id
				) sub
			), 0)::int AS avg_accuracy,
			(SELECT COUNT(*) FROM decks WHERE created_by = $1) AS decks_assigned
		FROM groups g
		JOIN group_members gm ON gm.group_id = g.id AND gm.user_id != $1
		JOIN users u ON u.id = gm.user_id
		WHERE g.created_by = $1
	`, teacherID).Scan(&d.TotalStudents, &d.ActiveToday, &d.AvgAccuracy, &d.DecksAssigned)
	if err != nil {
		return nil, err
	}

	var err2, err3, err4 error
	d.Attention, err2 = r.getAttentionItems(ctx, teacherID)
	d.Groups, err3 = r.getTeacherGroups(ctx, teacherID)
	d.RecentActivity, err4 = r.getActivity(ctx, `
		SELECT al.id, u.name, u.initials, al.kind, al.subject, al.target, al.created_at
		FROM activity_log al
		JOIN users u ON u.id = al.user_id
		WHERE al.group_id IN (SELECT id FROM groups WHERE created_by = $1)
		ORDER BY al.created_at DESC LIMIT 20
	`, teacherID)
	for _, e := range []error{err2, err3, err4} {
		if e != nil {
			return nil, e
		}
	}

	return &d, nil
}

func (r *TeacherRepository) getAttentionItems(ctx context.Context, teacherID string) ([]model.AttentionItem, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT DISTINCT ON (u.id)
			u.id, u.name, u.initials,
			g.id AS group_id, g.name AS group_name,
			CASE
				WHEN u.streak > 0 AND (u.last_active IS NULL OR u.last_active < CURRENT_DATE - INTERVAL '1 day')
				THEN 'urgent'
				ELSE 'warn'
			END AS severity,
			CASE
				WHEN u.streak > 0 AND (u.last_active IS NULL OR u.last_active < CURRENT_DATE - INTERVAL '1 day')
				THEN 'Streak ended — after ' || u.streak || ' days'
				WHEN u.last_active IS NULL
				THEN 'Never studied'
				ELSE 'No study for ' || (CURRENT_DATE - u.last_active::date) || ' days'
			END AS reason
		FROM users u
		JOIN group_members gm ON gm.user_id = u.id AND gm.user_id != $1
		JOIN groups g ON g.id = gm.group_id AND g.created_by = $1
		WHERE (
			(u.streak > 0 AND (u.last_active IS NULL OR u.last_active < CURRENT_DATE - INTERVAL '1 day'))
			OR (u.last_active IS NULL OR u.last_active < CURRENT_DATE - INTERVAL '2 days')
		)
		ORDER BY u.id,
			CASE WHEN u.streak > 0 AND (u.last_active IS NULL OR u.last_active < CURRENT_DATE - INTERVAL '1 day')
			THEN 0 ELSE 1 END
		LIMIT 5
	`, teacherID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []model.AttentionItem
	for rows.Next() {
		var item model.AttentionItem
		if err := rows.Scan(&item.UserID, &item.Name, &item.Initials,
			&item.GroupID, &item.GroupName, &item.Severity, &item.Reason); err != nil {
			return nil, err
		}
		item.Color = identityColor(item.UserID)
		items = append(items, item)
	}
	if items == nil {
		items = []model.AttentionItem{}
	}
	return items, nil
}

func (r *TeacherRepository) getTeacherGroups(ctx context.Context, teacherID string) ([]model.TeacherGroupSummary, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT
			g.id, g.name, g.emoji, g.color,
			COUNT(DISTINCT gm.user_id) AS member_count,
			COUNT(DISTINCT d.id)       AS deck_count,
			MAX(u.last_active)         AS last_active,
			COALESCE((
				SELECT AVG(
					CASE WHEN sub.total > 0
						THEN sub.mastered::float * 100 / sub.total
						ELSE 0 END
				)::int
				FROM (
					SELECT gm2.user_id,
						COUNT(*) FILTER (WHERE sp.interval_days >= 7) AS mastered,
						COUNT(*) AS total
					FROM group_members gm2
					LEFT JOIN srs_progress sp ON sp.user_id = gm2.user_id
					WHERE gm2.group_id = g.id AND gm2.user_id != $1
					GROUP BY gm2.user_id
				) sub
			), 0)::int AS class_avg
		FROM groups g
		JOIN group_members gm ON gm.group_id = g.id AND gm.user_id != $1
		JOIN users u ON u.id = gm.user_id
		LEFT JOIN collections c ON c.created_by = gm.user_id
		LEFT JOIN decks d ON d.collection_id = c.id
		WHERE g.created_by = $1
		GROUP BY g.id, g.name, g.emoji, g.color
		ORDER BY g.created_at DESC
	`, teacherID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var groups []model.TeacherGroupSummary
	for rows.Next() {
		var g model.TeacherGroupSummary
		if err := rows.Scan(&g.ID, &g.Name, &g.Emoji, &g.Color,
			&g.MemberCount, &g.DeckCount, &g.LastActive, &g.ClassAvg); err != nil {
			return nil, err
		}
		groups = append(groups, g)
	}

	for i := range groups {
		avatars, err := r.groupAvatars(ctx, groups[i].ID)
		if err != nil {
			return nil, err
		}
		groups[i].Avatars = avatars
	}

	if groups == nil {
		groups = []model.TeacherGroupSummary{}
	}
	return groups, nil
}

func (r *TeacherRepository) groupAvatars(ctx context.Context, groupID string) ([]model.MemberAvatar, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT u.id, u.initials
		FROM group_members gm
		JOIN users u ON u.id = gm.user_id
		WHERE gm.group_id = $1
		ORDER BY gm.joined_at
		LIMIT 4
	`, groupID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var avatars []model.MemberAvatar
	for rows.Next() {
		var userID, initials string
		if err := rows.Scan(&userID, &initials); err != nil {
			return nil, err
		}
		avatars = append(avatars, model.MemberAvatar{
			Initials: initials,
			Color:    identityColor(userID),
		})
	}
	if avatars == nil {
		avatars = []model.MemberAvatar{}
	}
	return avatars, nil
}

// getActivity is a shared helper that runs an activity_log query with one arg.
func (r *TeacherRepository) getActivity(ctx context.Context, query, arg string) ([]model.ActivityEvent, error) {
	rows, err := r.pool.Query(ctx, query, arg)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []model.ActivityEvent
	for rows.Next() {
		var e model.ActivityEvent
		if err := rows.Scan(&e.ID, &e.UserName, &e.Initials,
			&e.Kind, &e.Subject, &e.Target, &e.CreatedAt); err != nil {
			return nil, err
		}
		events = append(events, e)
	}
	if events == nil {
		events = []model.ActivityEvent{}
	}
	return events, nil
}

func (r *TeacherRepository) GetGroupStudents(ctx context.Context, groupID string) ([]model.StudentRosterItem, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT
			u.id, u.name, u.initials, u.streak,
			COALESCE((
				SELECT COUNT(*) FROM srs_progress sp
				WHERE sp.user_id = u.id AND sp.due_date <= CURRENT_DATE
			), 0) AS due_count,
			COALESCE((
				SELECT CASE WHEN t.total > 0
					THEN (t.mastered::float * 100 / t.total)::int
					ELSE 0 END
				FROM (
					SELECT
						COUNT(*) FILTER (WHERE sp.interval_days >= 7) AS mastered,
						COUNT(*) AS total
					FROM srs_progress sp
					WHERE sp.user_id = u.id
				) t
			), 0) AS progress_pct
		FROM group_members gm
		JOIN users u ON u.id = gm.user_id
		WHERE gm.group_id = $1
		ORDER BY gm.joined_at
	`, groupID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var students []model.StudentRosterItem
	for rows.Next() {
		var s model.StudentRosterItem
		if err := rows.Scan(&s.UserID, &s.Name, &s.Initials,
			&s.Streak, &s.DueCount, &s.ProgressPercent); err != nil {
			return nil, err
		}
		s.Color = identityColor(s.UserID)
		students = append(students, s)
	}
	if students == nil {
		students = []model.StudentRosterItem{}
	}
	return students, nil
}

func (r *TeacherRepository) GetGroupActivity(ctx context.Context, groupID string) ([]model.ActivityEvent, error) {
	return r.getActivity(ctx, `
		SELECT al.id, u.name, u.initials, al.kind, al.subject, al.target, al.created_at
		FROM activity_log al
		JOIN users u ON u.id = al.user_id
		WHERE al.group_id = $1
		ORDER BY al.created_at DESC
		LIMIT 50
	`, groupID)
}
