DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_type') THEN
        CREATE TYPE device_type AS ENUM ('display', 'lock', 'light', 'pump', 'fan');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_status') THEN
        CREATE TYPE device_status AS ENUM ('on', 'off', 'auto');
    END IF;
END $$;


CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type device_type NOT NULL,
    status device_status DEFAULT 'off' NOT NULL,
    last_status device_status,
    cage_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cage_id) REFERENCES cages(id) ON DELETE CASCADE
);

ALTER TABLE devices ADD CONSTRAINT valid_color_rgb CHECK (
  color_rgb IS NULL OR (
    jsonb_typeof(color_rgb) = 'object' AND
    color_rgb ? 'r' AND color_rgb ? 'g' AND color_rgb ? 'b' AND
    (color_rgb->>'r')::int BETWEEN 0 AND 255 AND
    (color_rgb->>'g')::int BETWEEN 0 AND 255 AND
    (color_rgb->>'b')::int BETWEEN 0 AND 255
  )
);
