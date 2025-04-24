DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cage_status') THEN
        CREATE TYPE cage_status AS ENUM ('active', 'inactive');
    END IF;
END $$;

CREATE TABLE cages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    user_id UUID NOT NULL,
    status cage_status DEFAULT 'inactive' NOT NULL,
    num_device INT DEFAULT 0, -- Added to match user_route.go
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_cages_user_id ON cages(user_id);