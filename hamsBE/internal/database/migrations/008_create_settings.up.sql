CREATE TABLE settings (
       cage_id UUID PRIMARY KEY REFERENCES cages(id) ON DELETE CASCADE,
       high_water_usage_threshold INT NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );