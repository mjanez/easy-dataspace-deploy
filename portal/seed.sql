-- Seed demo connectors (idempotent)
-- Variables are passed via psql -v from docker-compose

INSERT INTO organization (mds_id, name, url, created_by, created_at, registration_status, main_address, main_contact_email)
VALUES
  ('BPNL000001', 'Demo Authority', :'portal_public_url', 'system', now(), 'ACTIVE', 'Local', 'admin@example.com'),
  ('BPNL000002', 'Demo Participant', :'connector_c_public_url', 'system', now(), 'ACTIVE', 'Local', 'participant@example.com')
ON CONFLICT (mds_id) DO NOTHING;

INSERT INTO connector (connector_id, mds_id, provider_mds_id, type, environment, name, frontend_url, endpoint_url, management_url, participant_id, created_by, created_at)
VALUES
  ('conn-a', 'BPNL000001', 'BPNL000001', 'OWN', 'test', 'Connector A', :'connector_a_public_url', :'connector_a_internal_url' || '/api/v1/dsp', :'connector_a_internal_url' || '/api/management', :'connector_a_participant_id', 'system', now()),
  ('conn-b', 'BPNL000001', 'BPNL000001', 'OWN', 'test', 'Connector B', :'connector_b_public_url', :'connector_b_internal_url' || '/api/v1/dsp', :'connector_b_internal_url' || '/api/management', :'connector_b_participant_id', 'system', now()),
  ('conn-c', 'BPNL000002', 'BPNL000002', 'OWN', 'test', 'Connector C', :'connector_c_public_url', :'connector_c_internal_url' || '/api/v1/dsp', :'connector_c_internal_url' || '/api/management', :'connector_c_participant_id', 'system', now())
ON CONFLICT (connector_id) DO NOTHING;
