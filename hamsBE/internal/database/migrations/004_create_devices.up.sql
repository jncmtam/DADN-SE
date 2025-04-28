DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_type') THEN
        CREATE TYPE device_type AS ENUM ('display', 'lock', 'light', 'pump', 'fan');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_status') THEN
        CREATE TYPE device_status AS ENUM ('on', 'off');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_mode') THEN
        CREATE TYPE device_mod AS ENUM ('on', 'off', 'auto');
    END IF;
END $$;


CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    type device_type NOT NULL,
    status device_status DEFAULT 'off' NOT NULL,
    mode device_mod DEFAULT 'off' NOT NULL,
    last_mode device_mod,
    cage_id UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cage_id) REFERENCES cages(id) ON DELETE SET NULL
);

