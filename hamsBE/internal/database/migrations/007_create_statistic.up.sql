CREATE TABLE statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cage_id UUID NOT NULL,
    water_refill_sl INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cage_id) REFERENCES cages(id) ON DELETE CASCADE
);

CREATE TABLE water_refills (
    id UUID PRIMARY KEY,
    cage_id UUID NOT NULL,
    water_refill_sl INTEGER DEFAULT 1,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    FOREIGN KEY (cage_id) REFERENCES cages(id) ON DELETE CASCADE
);

CREATE INDEX idx_statistics_cage_id ON statistics(cage_id);
CREATE INDEX idx_statistics_created_at ON statistics(created_at);