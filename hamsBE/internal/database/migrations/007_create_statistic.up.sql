CREATE TABLE statistic (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cage_id UUID NOT NULL,
    water_refill_sl INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Added for consistency
    FOREIGN KEY (cage_id) REFERENCES cages(id) ON DELETE CASCADE
);

CREATE INDEX idx_statistic_cage_id ON statistic(cage_id);
CREATE INDEX idx_statistic_created_at ON statistic(created_at);