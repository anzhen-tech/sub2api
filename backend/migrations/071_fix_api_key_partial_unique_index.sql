-- 071_fix_api_key_partial_unique_index.sql
-- 修复 api_keys.key 软删除后无法重新创建相同 key 的问题
-- 将全局唯一约束替换为部分唯一索引（WHERE deleted_at IS NULL）
-- 软删除的 key 不占用唯一约束位置，允许删除后重新创建同一 key

-- 删除旧的全局唯一约束
ALTER TABLE api_keys DROP CONSTRAINT IF EXISTS api_keys_key_key;
DROP INDEX IF EXISTS api_keys_key_key;

-- 创建部分唯一索引：只对未删除的记录建立唯一约束
CREATE UNIQUE INDEX IF NOT EXISTS api_keys_key_unique_active
    ON api_keys(key)
    WHERE deleted_at IS NULL;
