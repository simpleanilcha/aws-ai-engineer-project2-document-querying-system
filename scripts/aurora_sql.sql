"CREATE EXTENSION IF NOT EXISTS vector;",
"CREATE SCHEMA IF NOT EXISTS bedrock_integration;",
"DO $$ BEGIN CREATE ROLE bedrock_user LOGIN; EXCEPTION WHEN duplicate_object THEN RAISE NOTICE 'Role already exists'; END $$;",
"GRANT ALL ON SCHEMA bedrock_integration to bedrock_user;",
"SET SESSION AUTHORIZATION bedrock_user;",
"""
CREATE TABLE IF NOT EXISTS bedrock_integration.bedrock_kb (
    id uuid PRIMARY KEY,
    embedding vector(1536),
    chunks text,
    metadata json
);
""",
"CREATE INDEX IF NOT EXISTS bedrock_kb_embedding_idx ON bedrock_integration.bedrock_kb USING hnsw (embedding vector_cosine_ops);"


-- MY WORKING CODE:

-- SQL script to create the Bedrock knowledge base table and supporting objects
-- Run this as the DB admin (the user in Secrets Manager) or via an elevated session

-- Ensure the vector extension is available (fixes the typo from your file)
CREATE EXTENSION IF NOT EXISTS vector;

-- Create schema
CREATE SCHEMA IF NOT EXISTS bedrock_integration;

-- Create role if not exists (silently continue if it already exists)
DO $$ BEGIN
  CREATE ROLE bedrock_user LOGIN;
EXCEPTION WHEN duplicate_object THEN
  RAISE NOTICE 'Role already exists';
END $$;

-- Grant privileges on schema to the role
GRANT ALL ON SCHEMA bedrock_integration TO bedrock_user;

-- Create the table expected by the Bedrock KB (name: bedrock_integration.bedrock_kb)
CREATE TABLE IF NOT EXISTS bedrock_integration.bedrock_kb (
  id uuid PRIMARY KEY,
  embedding vector(1536),
  chunks text,
  metadata json
);

-- Create the HNSW index for the vector column (if supported by your engine/version)
CREATE INDEX IF NOT EXISTS bedrock_kb_embedding_idx
  ON bedrock_integration.bedrock_kb USING hnsw (embedding vector_cosine_ops);

-- Create GIN index on chunks column for full-text search (required by Bedrock)
CREATE INDEX IF NOT EXISTS bedrock_kb_chunks_idx
  ON bedrock_integration.bedrock_kb USING gin (to_tsvector('english', chunks));

-- Optional: set owner of schema/table to bedrock_user (uncomment if desired and you have privileges)
-- ALTER SCHEMA bedrock_integration OWNER TO bedrock_user;
-- ALTER TABLE bedrock_integration.bedrock_kb OWNER TO bedrock_user;
