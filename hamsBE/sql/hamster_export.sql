SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Create the pgcrypto extension if it doesn't exist
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

-- Create the required ENUM types
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'action_enum') THEN 
        CREATE TYPE public.action_enum AS ENUM ('turn_on', 'turn_off', 'refill', 'lock'); 
    END IF; 
END $$;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cage_status') THEN 
        CREATE TYPE public.cage_status AS ENUM ('active', 'inactive'); 
    END IF; 
END $$;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'condition_enum') THEN 
        CREATE TYPE public.condition_enum AS ENUM ('>', '<', '=');
    END IF; 
END $$;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_status') THEN 
        CREATE TYPE public.device_status AS ENUM ('on', 'off', 'auto'); 
    END IF; 
END $$;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_type') THEN 
        CREATE TYPE public.device_type AS ENUM ('led', 'pump', 'fan'); 
    END IF; 
END $$;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sensor_type') THEN 
        CREATE TYPE public.sensor_type AS ENUM ('temperature', 'humidity', 'light', 'waterlevel'); 
    END IF; 
END $$;

-- Create tables if not exist
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
        CREATE TABLE public.users (
            id uuid DEFAULT gen_random_uuid() NOT NULL,
            username character varying(255) NOT NULL,
            email character varying(255) NOT NULL,
            avatar_url text DEFAULT ''::text,
            password_hash text NOT NULL,
            otp_secret text,
            is_email_verified boolean DEFAULT false,
            role character varying(10) NOT NULL,
            created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
            updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['admin'::character varying, 'user'::character varying])::text[])))
        );
    END IF;
END $$;

-- Insert initial users if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE username = 'admin') THEN
        INSERT INTO public.users (id, username, email, avatar_url, password_hash, otp_secret, is_email_verified, role, created_at, updated_at)
        VALUES 
            (gen_random_uuid(), 'admin', 'admin@example.com', '', 'hashed_password', NULL, true, 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
            (gen_random_uuid(), 'user1', 'user1@example.com', '', 'hashed_password', NULL, false, 'user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    END IF;
END $$;

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'cages') THEN
        CREATE TABLE public.cages (
            id uuid DEFAULT gen_random_uuid() NOT NULL,
            name character varying(255) NOT NULL,
            user_id uuid NOT NULL,
            status public.cage_status DEFAULT 'inactive'::public.cage_status NOT NULL,
            num_device integer DEFAULT 0,
            created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
            updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
        );
    END IF;
END $$;

-- Insert initial cages if they don't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM public.cages) THEN
        INSERT INTO public.cages (id, name, user_id, created_at, updated_at)
        VALUES 
            (gen_random_uuid(), 'Cage 1', (SELECT id FROM public.users WHERE username = 'user1' LIMIT 1), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    END IF;
END $$;

-- Ensure devices table exists
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'devices') THEN
        CREATE TABLE public.devices (
            id uuid DEFAULT gen_random_uuid() NOT NULL,
            name character varying(255) NOT NULL,
            type public.device_type NOT NULL,
            status public.device_status DEFAULT 'off'::public.device_status NOT NULL,
            last_status public.device_status,
            cage_id uuid,
            created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
            updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
        );
    END IF;
END $$;

-- Insert initial devices if they don't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM public.devices) THEN
        INSERT INTO public.devices (id, name, type, status, last_status, cage_id, created_at, updated_at)
        VALUES 
            (gen_random_uuid(), 'led', 'led', 'off', NULL, (SELECT id FROM public.cages LIMIT 1), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
            (gen_random_uuid(), 'fan', 'fan', 'off', NULL, (SELECT id FROM public.cages LIMIT 1), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    END IF;
END $$;

-- Ensure sensors table exists
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'sensors') THEN
        CREATE TABLE public.sensors (
            id uuid DEFAULT gen_random_uuid() NOT NULL,
            name character varying(255) NOT NULL,
            type public.sensor_type NOT NULL,
            value double precision NOT NULL,
            unit character varying(50),
            cage_id uuid,
            created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
            updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
        );
    END IF;
END $$;

-- Insert initial sensors if they don't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM public.sensors) THEN
        INSERT INTO public.sensors (id, name, type, value, unit, cage_id, created_at, updated_at)
        VALUES 
            (gen_random_uuid(), 'temperature', 'temperature', 25.5, '°C', (SELECT id FROM public.cages LIMIT 1), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
            (gen_random_uuid(), 'humidity', 'humidity', 60.0, '%', (SELECT id FROM public.cages LIMIT 1), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
            (gen_random_uuid(), 'light', 'light', 300.0, 'lx', (SELECT id FROM public.cages LIMIT 1), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
            (gen_random_uuid(), 'waterlevel', 'waterlevel', 50.0, 'cm', (SELECT id FROM public.cages LIMIT 1), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
            (gen_random_uuid(), 'waterlevel', 'waterlevel', 50.0, 'cm', (SELECT id FROM public.cages LIMIT 1), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
    END IF;
END $$;

-- Ensure automation_rules table exists
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'automation_rules') THEN
        CREATE TABLE public.automation_rules (
            id uuid DEFAULT gen_random_uuid() NOT NULL,
            sensor_id uuid NOT NULL,
            device_id uuid NOT NULL,
            cage_id uuid NOT NULL,
            condition public.condition_enum NOT NULL,
            threshold double precision NOT NULL,
            action public.action_enum NOT NULL,
            created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
            updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
        );
    END IF;
END $$;

-- Insert initial automation rules if they don't exist
