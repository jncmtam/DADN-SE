--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: action_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.action_enum AS ENUM (
    'turn_on',
    'turn_off'
);


ALTER TYPE public.action_enum OWNER TO postgres;

--
-- Name: cage_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.cage_status AS ENUM (
    'on',
    'off'
);


ALTER TYPE public.cage_status OWNER TO postgres;

--
-- Name: condition_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.condition_enum AS ENUM (
    '>',
    '<',
    '=',
    '>=',
    '<='
);


ALTER TYPE public.condition_enum OWNER TO postgres;

--
-- Name: device_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.device_status AS ENUM (
    'on',
    'off',
    'auto'
);


ALTER TYPE public.device_status OWNER TO postgres;

--
-- Name: device_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.device_type AS ENUM (
    'display',
    'lock',
    'light',
    'pump',
    'fan'
);


ALTER TYPE public.device_type OWNER TO postgres;

--
-- Name: sensor_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.sensor_type AS ENUM (
    'temperature',
    'humidity',
    'light',
    'distance',
    'weight'
);


ALTER TYPE public.sensor_type OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: automation_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.automation_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sensor_id uuid NOT NULL,
    device_id uuid NOT NULL,
    condition public.condition_enum NOT NULL,
    threshold double precision NOT NULL,
    unit character varying(50),
    action public.action_enum NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.automation_rules OWNER TO postgres;

--
-- Name: cages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    user_id uuid NOT NULL,
    status public.cage_status DEFAULT 'off'::public.cage_status NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.cages OWNER TO postgres;

--
-- Name: devices; Type: TABLE; Schema: public; Owner: postgres
--

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


ALTER TABLE public.devices OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    message text NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: otp_request; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.otp_request (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    otp_code character varying(6) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    is_used boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.otp_request OWNER TO postgres;

--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.refresh_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.refresh_tokens OWNER TO postgres;

--
-- Name: schedule_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schedule_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    device_id uuid NOT NULL,
    execution_time time without time zone NOT NULL,
    days text[] NOT NULL,
    action text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT schedule_rules_action_check CHECK ((action = ANY (ARRAY['turn_on'::text, 'turn_off'::text, 'refill'::text]))),
    CONSTRAINT valid_days CHECK ((days <@ ARRAY['mon'::text, 'tue'::text, 'wed'::text, 'thu'::text, 'fri'::text, 'sat'::text, 'sun'::text]))
);


ALTER TABLE public.schedule_rules OWNER TO postgres;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    dirty boolean NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- Name: sensors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sensors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    type public.sensor_type NOT NULL,
    value double precision,
    unit character varying(50),
    cage_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.sensors OWNER TO postgres;

--
-- Name: statistic; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.statistic (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    cage_id uuid NOT NULL,
    water_refill_sl integer DEFAULT 0,
    food_refill_sl integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.statistic OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

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


ALTER TABLE public.users OWNER TO postgres;

--
-- Data for Name: automation_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.automation_rules (id, sensor_id, device_id, condition, threshold, unit, action, created_at) FROM stdin;
92cb3395-508f-4c71-8179-609622999045	c190b289-d47f-490e-be48-5ea2d5709b8d	8b635d60-f6e4-45c2-a3a6-e64876abf932	<	30		turn_on	2025-04-23 20:57:07.182056
f6e8a035-8240-4aef-8bf0-e45a85801fc1	c190b289-d47f-490e-be48-5ea2d5709b8d	8b635d60-f6e4-45c2-a3a6-e64876abf932	<	30.6		turn_on	2025-04-23 20:58:24.172927
6a65b574-bc9a-4eb5-ac86-3cc762f3636c	c190b289-d47f-490e-be48-5ea2d5709b8d	8b635d60-f6e4-45c2-a3a6-e64876abf932	<	50		turn_off	2025-04-23 21:10:37.04195
\.


--
-- Data for Name: cages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cages (id, name, user_id, status, created_at, updated_at) FROM stdin;
e479a235-0406-480b-a955-29cac5c4c734	Cage 1	b7e4c791-f010-4773-a861-028ddaa2a478	off	2025-04-23 16:25:55.940557	2025-04-23 16:25:55.940557
fe0f0ab2-9ab8-4ed0-bfd9-76596871907c	Cage 2	b7e4c791-f010-4773-a861-028ddaa2a478	off	2025-04-23 16:26:00.887264	2025-04-23 16:26:00.887264
19833f74-f9c6-4ee3-999d-4b6cc4d7b119	Cage 3	b7e4c791-f010-4773-a861-028ddaa2a478	off	2025-04-23 16:26:03.818889	2025-04-23 16:26:03.818889
\.


--
-- Data for Name: devices; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.devices (id, name, type, status, last_status, cage_id, created_at, updated_at) FROM stdin;
8b635d60-f6e4-45c2-a3a6-e64876abf932	Device 1	fan	off	\N	e479a235-0406-480b-a955-29cac5c4c734	2025-04-23 17:01:24.645824	2025-04-23 17:01:24.645824
fd43f733-2c2c-47af-9eb2-11fa4d844f10	Device 2	light	off	\N	e479a235-0406-480b-a955-29cac5c4c734	2025-04-23 17:01:58.706077	2025-04-23 17:01:58.706077
45f914bc-0701-412d-9b44-65dc3fd9f0e4	Device 3	pump	off	\N	fe0f0ab2-9ab8-4ed0-bfd9-76596871907c	2025-04-23 19:49:47.719563	2025-04-23 19:49:47.719563
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notifications (id, message, user_id, created_at) FROM stdin;
\.


--
-- Data for Name: otp_request; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.otp_request (id, user_id, otp_code, expires_at, is_used, created_at) FROM stdin;
9b482b9b-bf91-4eb9-860d-bc3ff901bfe6	b7e4c791-f010-4773-a861-028ddaa2a478	748439	2025-04-23 21:19:50.138216	f	2025-04-23 21:14:50.138735
2b63f915-b759-4b08-b270-35834ede6de6	b7e4c791-f010-4773-a861-028ddaa2a478	097166	2025-04-23 21:20:21.880036	f	2025-04-23 21:15:21.880492
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.refresh_tokens (id, user_id, token, expires_at, created_at) FROM stdin;
3cd9b75f-d51e-452e-8e6f-10765b72b254	c3cad9bb-489e-400d-a001-6c6e29ee8005	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDYwMDk0NjYsInJvbGUiOiJhZG1pbiIsInVzZXJfaWQiOiJjM2NhZDliYi00ODllLTQwMGQtYTAwMS02YzZlMjllZTgwMDUifQ.--jtOACAhD7Hxv2YsW9N90-EWmcOt0lJDKCBs72CmJ8	2025-04-30 17:37:47.081509	2025-04-23 17:37:47.084855
70c9a0cd-40fd-48e5-a8d2-5f5a62a2f22e	174b3a1a-74eb-461d-8f73-0f78ad2b0827	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDYwMDk3MjIsInJvbGUiOiJ1c2VyIiwidXNlcl9pZCI6IjE3NGIzYTFhLTc0ZWItNDYxZC04ZjczLTBmNzhhZDJiMDgyNyJ9.2NSndFBKfJbiUyEx_mUPtMV4qrSh42EDYMbRbPz0UnQ	2025-04-30 17:42:02.645244	2025-04-23 17:42:02.64563
997ab90f-46fd-41be-923a-cbcac5e86498	b7e4c791-f010-4773-a861-028ddaa2a478	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDYwMjI2NDAsInJvbGUiOiJ1c2VyIiwidXNlcl9pZCI6ImI3ZTRjNzkxLWYwMTAtNDc3My1hODYxLTAyOGRkYWEyYTQ3OCJ9.8Jmja65waxYjRIfN9gT8vQeZjMsRxqVhCwjSTzNn2Cs	2025-04-30 21:17:20.313675	2025-04-23 21:17:20.313876
\.


--
-- Data for Name: schedule_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schedule_rules (id, device_id, execution_time, days, action, created_at) FROM stdin;
b637a829-2e1d-4e41-967c-9bdbf9c58b62	45f914bc-0701-412d-9b44-65dc3fd9f0e4	21:09:00	{mon}	refill	2025-04-23 21:09:47.066387
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (version, dirty) FROM stdin;
8	f
\.


--
-- Data for Name: sensors; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sensors (id, name, type, value, unit, cage_id, created_at) FROM stdin;
c190b289-d47f-490e-be48-5ea2d5709b8d	temp1	temperature	\N	oC	e479a235-0406-480b-a955-29cac5c4c734	2025-04-23 18:18:42.828017
\.


--
-- Data for Name: statistic; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.statistic (id, cage_id, water_refill_sl, food_refill_sl, created_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, username, email, avatar_url, password_hash, otp_secret, is_email_verified, role, created_at, updated_at) FROM stdin;
c3cad9bb-489e-400d-a001-6c6e29ee8005	admin1	admin@example.com		$2b$12$VTeoBTSBoWy6ncrFXqx4Vu/XVTaCXCjXrBY3gmqm7/1aCT6rnHLdi	\N	t	admin	2025-04-23 16:06:36.90715	2025-04-23 16:06:36.90715
174b3a1a-74eb-461d-8f73-0f78ad2b0827	tam	tam@gmail.com		$2b$12$VTeoBTSBoWy6ncrFXqx4Vu/XVTaCXCjXrBY3gmqm7/1aCT6rnHLdi	\N	f	user	2025-04-23 17:41:46.649255	2025-04-23 17:41:46.649255
b7e4c791-f010-4773-a861-028ddaa2a478	haizz	nialliceh@gmail.com	/avatars/b7e4c791-f010-4773-a861-028ddaa2a478.jpg	$2a$10$3lWr4WKfe2Lk1m8yZgZ2e.SfNw/FQsnYqq9bQgckMx19HjA23or5m	\N	f	user	2025-04-23 16:10:04.349965	2025-04-23 23:03:29.683332
\.


--
-- Name: automation_rules automation_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.automation_rules
    ADD CONSTRAINT automation_rules_pkey PRIMARY KEY (id);


--
-- Name: cages cages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cages
    ADD CONSTRAINT cages_pkey PRIMARY KEY (id);


--
-- Name: devices devices_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_name_key UNIQUE (name);


--
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: otp_request otp_request_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_request
    ADD CONSTRAINT otp_request_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: schedule_rules schedule_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_rules
    ADD CONSTRAINT schedule_rules_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sensors sensors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sensors
    ADD CONSTRAINT sensors_pkey PRIMARY KEY (id);


--
-- Name: statistic statistic_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statistic
    ADD CONSTRAINT statistic_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_automation_rules_device_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_automation_rules_device_id ON public.automation_rules USING btree (device_id);


--
-- Name: idx_automation_rules_sensor_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_automation_rules_sensor_id ON public.automation_rules USING btree (sensor_id);


--
-- Name: idx_cages_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cages_user_id ON public.cages USING btree (user_id);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_schedule_rules_device_days_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_schedule_rules_device_days_time ON public.schedule_rules USING btree (device_id, days, execution_time);


--
-- Name: idx_schedule_rules_device_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_schedule_rules_device_id ON public.schedule_rules USING btree (device_id);


--
-- Name: idx_sensors_cage_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sensors_cage_id ON public.sensors USING btree (cage_id);


--
-- Name: idx_statistic_cage_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_statistic_cage_id ON public.statistic USING btree (cage_id);


--
-- Name: idx_statistic_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_statistic_created_at ON public.statistic USING btree (created_at);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: automation_rules automation_rules_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.automation_rules
    ADD CONSTRAINT automation_rules_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: automation_rules automation_rules_sensor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.automation_rules
    ADD CONSTRAINT automation_rules_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES public.sensors(id) ON DELETE CASCADE;


--
-- Name: cages cages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cages
    ADD CONSTRAINT cages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: devices devices_cage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_cage_id_fkey FOREIGN KEY (cage_id) REFERENCES public.cages(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: otp_request otp_request_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.otp_request
    ADD CONSTRAINT otp_request_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: schedule_rules schedule_rules_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_rules
    ADD CONSTRAINT schedule_rules_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: sensors sensors_cage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sensors
    ADD CONSTRAINT sensors_cage_id_fkey FOREIGN KEY (cage_id) REFERENCES public.cages(id) ON DELETE CASCADE;


--
-- Name: statistic statistic_cage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.statistic
    ADD CONSTRAINT statistic_cage_id_fkey FOREIGN KEY (cage_id) REFERENCES public.cages(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

