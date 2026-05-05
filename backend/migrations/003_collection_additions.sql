-- Add emoji and color fields to collections
ALTER TABLE collections ADD COLUMN IF NOT EXISTS emoji TEXT NOT NULL DEFAULT '📚';
ALTER TABLE collections ADD COLUMN IF NOT EXISTS color TEXT NOT NULL DEFAULT '#99B7F5';
