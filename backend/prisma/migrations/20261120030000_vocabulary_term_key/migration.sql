-- Chặn trùng từ trong cùng học phần ở mức DB (an toàn khi nhiều request song song).
-- term_key = term đã chuẩn hoá: trim, gộp khoảng trắng, viết thường (giống termKey() trong code).

-- 1. Thêm cột cho phép null để điền dữ liệu cho các từ đã có
ALTER TABLE "vocabularies" ADD COLUMN "term_key" TEXT;

UPDATE "vocabularies"
SET "term_key" = lower(regexp_replace(btrim("term"), '\s+', ' ', 'g'));

-- 2. Nếu dữ liệu cũ đã lỡ trùng, giữ từ tạo sớm nhất, gắn hậu tố cho các bản sau
UPDATE "vocabularies" v
SET "term_key" = v."term_key" || '#' || v."id"
FROM (
  SELECT "id",
         row_number() OVER (
           PARTITION BY "collection_id", "term_key" ORDER BY "created_at", "id"
         ) AS rn
  FROM "vocabularies"
) d
WHERE d."id" = v."id" AND d.rn > 1;

-- 3. Bắt buộc và duy nhất theo học phần
ALTER TABLE "vocabularies" ALTER COLUMN "term_key" SET NOT NULL;

CREATE UNIQUE INDEX "vocabularies_collection_id_term_key_key"
  ON "vocabularies"("collection_id", "term_key");
