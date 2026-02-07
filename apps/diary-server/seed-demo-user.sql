-- Insert Demo User for Local Development
INSERT INTO users (id, email, is_verified)
VALUES ('11111111-1111-1111-1111-111111111111', 'demo@example.com', true)
ON CONFLICT (id) DO NOTHING;
