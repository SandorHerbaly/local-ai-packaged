CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS n8n_vectors_table (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    text TEXT,
    metadata JSONB,
    embedding VECTOR(768)
);

