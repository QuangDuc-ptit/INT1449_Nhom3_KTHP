-- Tìm kiếm học phần bằng ILIKE '%từ khoá%' (GET /collections?search=) dùng được index nhờ pg_trgm
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS "collections_title_trgm_idx"
  ON "collections" USING GIN ("title" gin_trgm_ops);

CREATE INDEX IF NOT EXISTS "collections_description_trgm_idx"
  ON "collections" USING GIN ("description" gin_trgm_ops);
