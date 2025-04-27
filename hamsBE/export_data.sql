--
-- PostgreSQL database dump
--

-- Dumped from database version 15.12 (Homebrew)
-- Dumped by pg_dump version 15.12 (Homebrew)

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

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: action_enum; Type: TYPE; Schema: public; Owner: minhtam
--

CREATE TYPE public.action_enum AS ENUM (
    'turn_on',
    'turn_off',
    'refill',
    'lock'
);


ALTER TYPE public.action_enum OWNER TO minhtam;

--
-- Name: cage_status; Type: TYPE; Schema: public; Owner: minhtam
--

CREATE TYPE public.cage_status AS ENUM (
    'active',
    'inactive'
);


ALTER TYPE public.cage_status OWNER TO minhtam;

--
-- Name: condition_enum; Type: TYPE; Schema: public; Owner: minhtam
--

CREATE TYPE public.condition_enum AS ENUM (
    '>',
    '<',
    '='
);


ALTER TYPE public.condition_enum OWNER TO minhtam;

--
-- Name: device_status; Type: TYPE; Schema: public; Owner: minhtam
--

CREATE TYPE public.device_status AS ENUM (
    'on',
    'off',
    'auto'
);


ALTER TYPE public.device_status OWNER TO minhtam;

--
-- Name: device_type; Type: TYPE; Schema: public; Owner: minhtam
--

CREATE TYPE public.device_type AS ENUM (
    'display',
    'lock',
    'light',
    'pump',
    'fan'
);


ALTER TYPE public.device_type OWNER TO minhtam;

--
-- Name: sensor_type; Type: TYPE; Schema: public; Owner: minhtam
--

CREATE TYPE public.sensor_type AS ENUM (
    'temperature',
    'humidity',
    'light',
    'distance'
);


ALTER TYPE public.sensor_type OWNER TO minhtam;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: automation_rules; Type: TABLE; Schema: public; Owner: minhtam
--

CREATE TABLE public.automation_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    sensor_id uuid NOT NULL,
    device_id uuid NOT NULL,
    cage_id uuid NOT NULL,
    condition public.condition_enum NOT NULL,
    threshold double precision NOT NULL,
    action public.action_enum NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    unit character varying(10)
);


ALTER TABLE public.automation_rules OWNER TO minhtam;

--
-- Name: cages; Type: TABLE; Schema: public; Owner: minhtam
--

CREATE TABLE public.cages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL,
    user_id uuid NOT NULL,
    status public.cage_status DEFAULT 'inactive'::public.cage_status NOT NULL,
    num_device integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    num_sensor integer DEFAULT 0
);


ALTER TABLE public.cages OWNER TO minhtam;

--
-- Name: devices; Type: TABLE; Schema: public; Owner: minhtam
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


ALTER TABLE public.devices OWNER TO minhtam;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: minhtam
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    cage_id uuid NOT NULL,
    type character varying(50) NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT notifications_type_check CHECK (((type)::text = ANY (ARRAY[('info'::character varying)::text, ('warning'::character varying)::text, ('error'::character varying)::text, ('notification'::character varying)::text])))
);


ALTER TABLE public.notifications OWNER TO minhtam;

--
-- Name: otp_requests; Type: TABLE; Schema: public; Owner: minhtam
--

CREATE TABLE public.otp_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    otp_code character varying(6) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    is_used boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.otp_requests OWNER TO minhtam;

--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: minhtam
--

CREATE TABLE public.refresh_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.refresh_tokens OWNER TO minhtam;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: minhtam
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    dirty boolean NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO minhtam;

--
-- Name: sensors; Type: TABLE; Schema: public; Owner: minhtam
--

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


ALTER TABLE public.sensors OWNER TO minhtam;

--
-- Name: settings; Type: TABLE; Schema: public; Owner: minhtam
--

CREATE TABLE public.settings (
    cage_id uuid NOT NULL,
    high_water_usage_threshold integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.settings OWNER TO minhtam;

--
-- Name: statistics; Type: TABLE; Schema: public; Owner: minhtam
--

CREATE TABLE public.statistics (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    cage_id uuid NOT NULL,
    water_refill_sl integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.statistics OWNER TO minhtam;

--
-- Name: users; Type: TABLE; Schema: public; Owner: minhtam
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


ALTER TABLE public.users OWNER TO minhtam;

--
-- Name: water_refills; Type: TABLE; Schema: public; Owner: minhtam
--

CREATE TABLE public.water_refills (
    id uuid NOT NULL,
    cage_id uuid NOT NULL,
    water_refill_sl integer DEFAULT 1,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.water_refills OWNER TO minhtam;

--
-- Data for Name: automation_rules; Type: TABLE DATA; Schema: public; Owner: minhtam
--

COPY public.automation_rules (id, sensor_id, device_id, cage_id, condition, threshold, action, created_at, updated_at, unit) FROM stdin;
550e8400-e29b-41d4-a716-446655440400	550e8400-e29b-41d4-a716-446655440200	550e8400-e29b-41d4-a716-446655440301	550e8400-e29b-41d4-a716-446655440100	>	30	turn_on	2025-04-01 12:00:00	2025-04-01 12:00:00	\N
550e8400-e29b-41d4-a716-446655440401	550e8400-e29b-41d4-a716-446655440201	550e8400-e29b-41d4-a716-446655440301	550e8400-e29b-41d4-a716-446655440100	>	80	turn_on	2025-04-01 12:00:00	2025-04-01 12:00:00	\N
550e8400-e29b-41d4-a716-446655440402	550e8400-e29b-41d4-a716-446655440202	550e8400-e29b-41d4-a716-446655440300	550e8400-e29b-41d4-a716-446655440101	<	16	refill	2025-04-02 08:00:00	2025-04-02 08:00:00	\N
b0b1eae4-c41b-4ed8-a90e-6be1b43365e8	00000000-0000-0000-0000-000000000003	00000000-0000-0000-0000-000000000006	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	=	31	turn_off	2025-04-27 03:55:37.672172	2025-04-27 03:55:37.672172	\N
\.


--
-- Data for Name: cages; Type: TABLE DATA; Schema: public; Owner: minhtam
--

COPY public.cages (id, name, user_id, status, num_device, created_at, updated_at, num_sensor) FROM stdin;
550e8400-e29b-41d4-a716-446655440100	Hamster Cage 1	550e8400-e29b-41d4-a716-446655440000	active	2	2025-04-01 12:00:00	2025-04-01 12:00:00	0
550e8400-e29b-41d4-a716-446655440101	Hamster Cage 2	550e8400-e29b-41d4-a716-446655440000	inactive	1	2025-04-02 08:00:00	2025-04-02 08:00:00	0
550e8400-e29b-41d4-a716-446655440102	Admin Cage	550e8400-e29b-41d4-a716-446655440001	active	3	2025-04-01 13:00:00	2025-04-01 13:00:00	0
0e890a13-cfe5-4794-8b94-7ccf6e07d80f	Cage0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	inactive	0	2025-04-25 13:36:16.717264	2025-04-25 13:36:16.717264	0
59dd348e-c2cf-4703-8f08-90e361caaf3d	Cage1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	inactive	0	2025-04-25 13:36:44.290104	2025-04-25 13:36:44.290104	0
8d05bb9a-0ef1-4679-9d89-13b1be1ca219	cage1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	inactive	3	2025-04-25 14:19:16.052488	2025-04-25 14:19:16.052488	4
\.


--
-- Data for Name: devices; Type: TABLE DATA; Schema: public; Owner: minhtam
--

COPY public.devices (id, name, type, status, last_status, cage_id, created_at, updated_at) FROM stdin;
00000000-0000-0000-0000-000000000006	led	light	off	off	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	2025-04-25 14:35:14.987288	2025-04-27 10:20:55
00000000-0000-0000-0000-000000000007	pump	pump	off	on	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	2025-04-25 14:35:14.987288	2025-04-27 07:47:45.030702
00000000-0000-0000-0000-000000000005	fan	fan	off	off	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	2025-04-25 14:35:14.987288	2025-04-27 10:19:26
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: minhtam
--

COPY public.notifications (id, user_id, cage_id, type, title, message, is_read, created_at) FROM stdin;
7599bd6e-12b3-447c-b93e-c2fc34c6debc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device fan: Action turn_off executed	Device fan set to off	f	2025-04-27 04:22:32.869947
e214362a-b861-4b10-8d81-8ba8cb34fea4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device fan: Status changed	Device fan set to off	f	2025-04-27 04:22:32
db70dda5-6d49-4fa6-81c6-cffe56f26b49	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device fan: Status changed	Device fan set to off	f	2025-04-27 04:22:32
5df4d67c-b564-493e-a5f0-2736a458fb94	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device fan: Action turn_on executed	Device fan set to on	f	2025-04-27 04:22:37.861705
fd55531e-8506-49ea-acfd-d5e65abee32d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device fan: Status changed	Device fan set to on	f	2025-04-27 04:22:37
8a655a45-fb28-4b14-8d3b-1e42edbbe3e3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device fan: Status changed	Device fan set to on	f	2025-04-27 04:22:37
01b9c01b-2b62-4143-85a4-ef76c74b6f9e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Action turn_on executed	Device pump set to on	f	2025-04-27 04:26:38.324574
6bc12fba-7dad-4e25-871c-baf858e56bdd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:01
8056f5e8-9104-43c0-9ed2-3ba7f1acf2e6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3640.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:06
eed363f9-93f7-44a9-a5d7-e25cb110563a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device: Pump stopped	Pump turned off after 2-second refill	f	2025-04-27 04:26:40.328892
b5ff6a62-5d94-470f-8f44-7de8dac01f68	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 04:26:40
d558db1c-c659-4dae-94a9-a57e98fd2fb4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 04:26:40
cad48445-e480-4254-b2eb-76fede324cac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Action turn_on executed	Device pump set to on	f	2025-04-27 04:26:40.530258
46fa5a80-e39b-423e-a8b5-07879f2bdf9e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3654.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:11
78c546a3-fce1-4909-b33d-797d946db63a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3647.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:16
6566e24f-38fd-4887-b5c1-cf2912d17227	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device: Pump stopped	Pump turned off after 2-second refill	f	2025-04-27 04:26:42.537662
5aa33431-d9e6-4fd6-9c8f-4e0bbfb928e9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 04:26:42
e5876885-3d5a-483d-af6d-e56eae864615	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 04:26:42
c8478d95-8da3-4dde-98a1-5c09fcb7a2cc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Action turn_on executed	Device pump set to on	f	2025-04-27 05:12:33.827272
ee3059c1-6338-4fba-ace7-278a7e954c47	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:27
f5dd6b29-693c-4bb6-a893-a78582279a25	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3154.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
4b078915-0ae9-4e93-89a1-f30ffbfefc31	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device: Pump stopped	Pump turned off after 2-second refill	f	2025-04-27 05:12:35.83236
eaccfdf4-7ab1-4360-a657-1fa075a7a654	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 05:12:35
05d07393-3cb1-49de-ac9a-704fc95b1df1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 05:12:35
a67e1cb7-e539-4c7c-89fa-77d7f91e9311	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Action refill executed	Device pump set to on	f	2025-04-27 05:13:57.97089
1c24b513-cd65-48f1-a73d-75292442b054	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:32
4fad330d-32f1-4082-ad77-03575902a5ae	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3178.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
f133d159-46b0-46da-9a21-af23f2144a82	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device: Pump stopped	Pump turned off after 2-second refill	f	2025-04-27 05:13:59.975486
446d620f-1a40-49b5-a91b-a74533f27b96	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 05:13:59
6692adb7-818b-4c0b-b035-7da79938e7c3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 05:13:59
3d1b5ff0-953f-499b-99f9-1114517020d5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Action refill executed	Device pump set to on	f	2025-04-27 05:14:00.507417
c999acf5-5c4e-4ef5-b0a1-454642341ccf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:37
aff0a003-e294-4229-9425-2a91aa3e5a1e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3169.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
d86fa8aa-d0ef-48c8-8f34-589203814931	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device: Pump stopped	Pump turned off after 2-second refill	f	2025-04-27 05:14:02.512603
fe0d0f13-7de3-48aa-beb9-0f5311e40ebc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 05:14:02
4ffa577c-aae7-47d0-99f2-d43d24d644f5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 05:14:02
06a09c6f-700f-4471-ae47-65b7f7fd0a62	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Action refill executed	Device pump set to on	f	2025-04-27 05:14:36.688899
deed86c7-717a-4bf3-90f7-112709564105	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device: Pump stopped	Pump turned off after 2-second refill	f	2025-04-27 05:14:38.6934
37c9656c-e232-4905-8c45-47de2440aff5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 05:14:38
2114dabe-a3a6-4c79-9846-963e79c8f1b0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 05:14:38
cbb90572-02d3-4187-8680-ff450a04b8d0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Action refill executed	Device pump set to on	f	2025-04-27 05:22:39.209939
f62eaa39-f123-496d-b3ae-4850573e889f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device: Pump stopped	Pump turned off after 2-second refill	f	2025-04-27 05:22:41.216064
79f6887b-edba-40d8-9eab-a972252a6892	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 05:22:41
28c7ebaf-0266-409a-acb7-08b81a1ac0c7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Status changed	Device pump set to off	f	2025-04-27 05:22:41
6585d0e1-3882-4970-b854-cf0f4958e4a0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Action turn_off executed	Device led set to off	f	2025-04-27 05:39:41.526169
c3ff27da-7361-4adc-ae99-e96b4d00e5b8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Status changed	Device led set to off	f	2025-04-27 05:39:41
957d7765-8c0e-4e52-9302-2c246822d27a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Status changed	Device led set to off	f	2025-04-27 05:39:41
96392b42-c707-4510-9c6b-0f95922a30ae	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Action turn_on executed	Device led set to on	f	2025-04-27 05:39:48.043504
d09194b4-bd2b-4f4b-8250-cf096385af1e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Status changed	Device led set to on	f	2025-04-27 05:39:48
542f8753-af33-4abd-8053-f2da02707775	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Status changed	Device led set to on	f	2025-04-27 05:39:48
ccb2046d-0d10-4531-8904-fe43eae0bc8c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:03
fec6ec96-a7ff-4bf5-9538-498626112006	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:03
6aa7c155-f095-4b42-b4cb-84ea31ea1495	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2279.0 lux	f	1970-01-01 08:00:03
b8d4a70c-87b6-4b22-ba41-6e54ddd0c7b3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -95.0%	f	1970-01-01 08:00:03
3ba1069f-6651-431b-9953-454bd2949574	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:08
c40bfced-f63f-4bf1-a5c8-b9153a80a35f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2278.0 lux	f	1970-01-01 08:00:08
27e78d34-baea-4428-ba56-cee542495696	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:08
bc81af39-6ce6-457f-9c33-c5c0b04736b8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:13
872f06c1-01c2-410a-af69-8728c93a81c4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2417.0 lux	f	1970-01-01 08:00:13
fc0e6f6e-c95f-418c-8aca-1b3dcc1d21ab	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:01
ea39d2db-4c57-43eb-be15-ee06144dab49	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3640.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:06
b2d16352-30be-4bb9-b31c-315549b9f720	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3654.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:11
5d683b3b-4a93-412d-96c1-984f53abac3c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3647.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:16
4b126391-72c3-465d-a502-f838895f1d66	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.7%. Consider improving ventilation.	f	1970-01-01 08:00:57
50db977b-9fdc-4378-b5a9-cb9e19a4c09c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3207.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:57
aa806ad7-36cf-4382-96b3-24cf4bb0c8e4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.7%. Consider improving ventilation.	f	1970-01-01 08:01:02
e5e90114-938f-451c-a28b-fae761786ec0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3199.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:02
acde2b18-b164-4b94-8475-23a786944afd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:27
9c44a239-be7a-49d8-bcf2-018e921f7f5f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3213.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
f4ee21fc-7b58-41bd-afa5-00d64f4fd23a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:48
8cd56906-8542-4bcb-82d4-875a4091526e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3305.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:48
f51cedf9-b8bf-4221-aaa0-d06cd8b70dc3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:42
5ad5ecb2-b029-47a6-8f0b-1a4f48a55ddf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3314.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
c131dc33-66f7-4551-950c-69f99460f1e8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:01
a58074bc-6c19-4aab-a56a-de9d55e1ab38	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3329.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
9214e3a8-8c2f-4630-a3e2-803920bf2485	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:01:02
3a7a41ea-3a54-4b6b-8349-59edf377a492	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:01:07
303105ea-26d7-4fde-83c5-9c3cf44d2fc7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3361.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:07
b2e5d2e9-b2a8-409b-8411-89ab75066fae	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
844fae78-d893-49f1-a2c3-e7e37790010c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3369.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
194302a9-e134-4785-a1bb-8d19bd16bc30	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:17
2b51809c-a105-4f31-ac44-8bb7f79c1dc1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3374.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
405d6039-6e46-46c1-805c-e5558be5cff4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:37
40893daf-0860-419c-bc69-ce4173ae350c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3373.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
a0a83391-43db-4dee-9369-b28bc5170d51	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
5d379cf3-03c8-406b-a014-1f0b997a29c4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3373.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
2c6b5e3d-d9db-4894-9020-640d47f6fefd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
8d747766-8a00-44b3-a829-94fcc1bce9f7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3389.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
eb61af78-329b-4e03-9939-c3c92a403a39	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:06
6a85b0ab-86e8-4eca-ba5b-5090aa6b60f8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3387.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
c5736d90-9d24-4e03-bd00-efd16ab20719	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
37dfe44f-2788-405a-8e87-93c432720f1b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3377.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
69d928a6-76ec-487f-b973-2b175103c9b2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:52
8e071ee6-b557-4cb8-8863-2e09813fe6bd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:18
dbecdd8d-6c9c-442a-95fd-dad97fa46f67	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2371.0 lux	f	1970-01-01 08:00:18
7021b930-48d1-4458-801a-fc161dacd528	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:23
e01df6ed-cc5c-405e-a864-93daf880281f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2350.0 lux	f	1970-01-01 08:00:23
d7fccc1f-5cbb-4eb6-a607-423c0d7ee5c4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:28
0048c73e-78ad-4779-a0a9-e78c5eaa00d3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2340.0 lux	f	1970-01-01 08:00:28
7d332c8f-b701-479b-bcc4-5187d2769d96	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:33
9977567d-ddd5-423c-bab6-34c99ea21e53	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2347.0 lux	f	1970-01-01 08:00:33
5d406241-c758-40d3-a192-83dd57c1c63c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -795.0%	f	1970-01-01 08:00:33
d46cc8c1-d250-4d52-9229-871d4870e300	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:38
a795c674-1de3-461b-80b7-bedb452b4fea	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2349.0 lux	f	1970-01-01 08:00:38
8c448623-c2ae-4b85-9139-8114422b685e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:38
85d985f9-f90e-435f-8e50-4e3dd9897889	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:43
18f03140-309a-4806-934f-83f665063a4d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2370.0 lux	f	1970-01-01 08:00:43
e8aa2c36-1407-4694-aaf1-627afb16b08d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:43
c1631f8f-fd55-479c-8186-2b126547c7dd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:48
5c865c63-c9a4-436a-a522-95b6becee468	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2383.0 lux	f	1970-01-01 08:00:48
a49495e8-4e90-48a1-a33c-af046cb59752	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:48
69f75548-f4c1-4e96-86ca-6fee9b8076ef	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:01
8d91e534-f4ae-4bdb-9d72-bd1e4587aa3b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2379.0 lux	f	1970-01-01 08:00:01
bd04bd6b-a62f-4fd9-ae9a-1de11d003e5f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:01
06c83ab7-f700-4352-b1f5-dbfa39566326	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:06
fe814f69-b084-47d6-9c02-b59b1ff001f2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2374.0 lux	f	1970-01-01 08:00:06
6c38c323-1141-4626-9e5c-2aff8f2833d6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:06
eef40051-8538-479c-b2f3-68fc810db361	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:12
f8cf8ae1-8b8c-4db4-914d-1450104f9765	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2379.0 lux	f	1970-01-01 08:00:12
6977d5b0-e172-458a-85ee-6bd5c486ec3d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:12
340f3222-02bf-4a7d-ae7d-c8b6949948d5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.5%	f	1970-01-01 08:00:17
9c60f113-49c3-4361-b673-396d9473c708	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2384.0 lux	f	1970-01-01 08:00:17
c4d4d7c6-e9d7-4277-b310-da8b2a36039f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:17
2a62f80f-90a1-49c1-8422-17c2e6d7d9af	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.5%	f	1970-01-01 08:00:22
4e41309d-e9a3-4c18-845d-88d8fcad12b1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2376.0 lux	f	1970-01-01 08:00:22
64ee7b37-a7c2-47a5-944f-cd937cd5a10f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:22
9396b164-99d2-4b85-8313-3725c782a172	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:22
6eafbdfc-562e-46d8-a3a0-f6764f570a8d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3183.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
b90125a6-10b6-4388-a52d-478550354734	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:27
c635aec6-fb5a-442e-aeb5-11067802d3d9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3187.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
ab6ca75f-fe34-4910-99e3-beaeb84bb4eb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:32
9d535c08-3dac-4681-a556-7e8cd5b63659	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3151.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
c1468434-0b52-428d-a798-f32b04302a75	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:37
6ba68980-6bd5-4a9e-84e3-7e0222ff7675	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3143.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
6d7f6201-eb03-4a04-9b26-5d90add276fe	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:42
aeeabc79-0715-4ee3-b696-a4fb505df496	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3154.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
a4660f35-40b1-4cba-a887-acaeb81d5f94	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.7%. Consider improving ventilation.	f	1970-01-01 08:00:57
152163e3-5aa7-4d5f-a555-01b22c331cac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3207.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:57
2c0006e8-65c6-4eec-afd2-1440032c6aff	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.7%. Consider improving ventilation.	f	1970-01-01 08:01:02
94780b75-796d-4eef-ae67-2aad4e9ca5b4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3199.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:02
73bb743c-5e44-4f69-bad8-43eade51092a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:27
74cae9d9-bff9-47bd-b5db-48efe242509d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:18
690e7b49-0097-4ed9-ab63-fd4f6f584769	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2371.0 lux	f	1970-01-01 08:00:18
047c078b-97fe-4f2e-9687-6fa704628e29	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:23
8e7d4e6e-0b1b-4007-b571-b6f6784d2618	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2350.0 lux	f	1970-01-01 08:00:23
08f4a43c-bc9d-4727-8f35-04d057c87ed6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:28
7f7fffad-b57c-4a96-8765-609a761c02d4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2340.0 lux	f	1970-01-01 08:00:28
b81b5ae4-797d-4f2f-9719-0c2cf82f7f22	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:33
a05d7b53-8112-4cc6-bb91-a067f5f4ac1e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2347.0 lux	f	1970-01-01 08:00:33
d7a20aca-3c84-4ee7-8921-bcd85baeddf2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -795.0%	f	1970-01-01 08:00:33
496f72c2-03d7-41e5-bf77-0e8f1b336c25	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:38
4426dafc-57ac-4485-b6a4-34c76fedd1eb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2349.0 lux	f	1970-01-01 08:00:38
cb68b493-eb08-4512-82f7-2261d1b003d2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:38
95abe716-3974-48dd-a6f5-703f2812df82	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:43
60cf5158-7efc-47b9-b39e-4aa8fbdea01e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2370.0 lux	f	1970-01-01 08:00:43
15c11d03-5322-4272-84b0-35c5230bbdc7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:43
9a854c41-56ba-489c-8bf5-92f6defcd567	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:48
bc5df2e9-f0a7-4461-8fa2-e9665360a39a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2383.0 lux	f	1970-01-01 08:00:48
8ee5c323-21d2-47b8-b892-4092cd4d794e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:48
dd301e8a-aae2-4056-93dd-ee448c8128ce	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:01
c66f1b61-288a-4d17-9862-28877e53054c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2379.0 lux	f	1970-01-01 08:00:01
48f36770-cf41-4d4a-99b0-35b5ff12e3f3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:01
291e9466-bdc4-457a-bfb2-4a563a1b7a34	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:06
503cfeb9-d0b4-4928-8155-5b618b7db298	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2374.0 lux	f	1970-01-01 08:00:06
3a7710a4-d9a4-4ce7-9c34-90b3a4b66805	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:06
624f58b7-b17d-41a7-9460-5fb035127cbf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:12
f97831e5-cf55-4cd7-ab1f-761facfee2a5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2379.0 lux	f	1970-01-01 08:00:12
07734d01-1042-4cdd-8e18-5f6a9254f13d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:12
57c4cfb3-4e93-4256-8164-dc2ed6efb0b1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.5%	f	1970-01-01 08:00:17
033fc67b-3971-43b1-a17c-340b38bb3b67	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2384.0 lux	f	1970-01-01 08:00:17
e58a9bbe-60e3-41de-b693-b640378e4ab8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:17
78607fd3-b99a-4d5d-97db-b6f3896584bf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.5%	f	1970-01-01 08:00:22
1b970afc-0132-40ef-ace6-ad9de6c4049d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2376.0 lux	f	1970-01-01 08:00:22
3a123121-8113-454e-819e-f1bd481b27e8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:22
b9c9f6b1-876c-42f5-8f70-567e66f41294	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:22
8379cb93-51c7-4f15-9d05-8720832dceaa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3183.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
5c07f6d5-83a1-48bc-9a99-5b9079a1d29b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:27
3445cba6-6791-4962-afc6-38feac944e53	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3187.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
c0fbbd9a-5951-46b7-b172-a3e09c7d9c67	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:32
35db774e-03f6-46ff-b789-eabe45a776e3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3151.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
63b12c2b-f1ae-4355-9d38-e2b7bc54c592	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:37
2280befb-0815-4a2b-b6f4-f348db99c456	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3143.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
e9818831-890f-474b-b063-b9cf58b8107c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:42
93612419-04e8-4651-9407-c78ffbb5d35c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3154.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
d958b869-a8f2-4a01-96a6-18ab5259a9e6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.7%. Consider improving ventilation.	f	1970-01-01 08:01:07
b06b53c2-2f4b-4d53-aba3-038080cf131d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3202.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:07
b0ddb7d9-7989-47f8-8fae-b010af53919a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3213.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
5877e3a2-27ca-481e-ad0a-3d8ecfc2db21	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:54
ce028fcf-2528-4f0d-8285-2c7f7239e21a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3312.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:54
13a061bf-6b66-4f50-9315-46740c458ffb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.5%	f	1970-01-01 08:00:27
757ee2f6-5243-40a1-9133-9ccc1e5d507e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2395.0 lux	f	1970-01-01 08:00:27
4d1b5fbb-54fe-4aad-857c-677cfce92d6c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:27
a13c0e75-e9a3-4a2f-ae96-732c58ca0272	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.5%	f	1970-01-01 08:00:32
67c3543c-65cd-497a-9507-8aa61d42899c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2394.0 lux	f	1970-01-01 08:00:32
468f134e-4071-4862-8ce4-2cbd3e0e6ec3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:32
4c65f081-27fe-4c33-9bb7-5d3486d9649b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.6%	f	1970-01-01 08:00:52
d52e00dc-ac4c-4fe0-a32c-6a5e406d28e5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2394.0 lux	f	1970-01-01 08:00:52
82bb2990-2dcf-44fc-beb9-e20d3ba385d8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -255.0%	f	1970-01-01 08:00:52
03d0c610-7236-4b9f-b88d-3563856f38f6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3664.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:21
3b89167b-105d-4cd3-919b-08197e9ea2b5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3659.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
5fdf8428-3ed6-42d2-bfaa-4fbd8ec12d08	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:01:02
bb99142f-be47-4b5b-9846-b632002fc212	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3145.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:02
1ccc33ad-aabf-4458-ba1d-4bb42060af99	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:01:23
d292f429-e7c5-49d3-86c5-04209bb91dad	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3101.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
4267703e-ddc0-40a6-8258-65c111f605df	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:01:28
219f9130-97f0-432f-855e-90438f988a30	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3088.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
12b31a18-7b04-4846-802d-6491db3d8312	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:01
7cadefc7-4070-4edd-8370-0d8253d18fb3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3094.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
d8f01019-47af-45ac-9083-b5729b5717f3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:06
d3a3f70e-675c-4f6c-bc1a-64d4ae3640d4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3071.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
af75342d-be6e-49a0-93c0-0ac538de34b0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:12
fbfc1a00-7da7-4840-9d26-df1f103bc951	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3059.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
f5c198ab-4b67-4ac6-ae5a-eb1829e208a4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.7%. Consider improving ventilation.	f	1970-01-01 08:01:07
15c8ada8-3e32-486a-9889-4fa8c0d77bc3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3202.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:07
8ed12969-9402-4f68-afe4-75ba7d9aeea8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:32
fa49a9b3-e426-435a-81d5-056612cf6ff8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3213.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
713f41a3-4dc6-4b5c-b4cf-af3f5e1b2a4a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:54
6159b836-b464-4950-9e10-1bca8fb490ea	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3312.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:54
20f9f77c-bd86-4de9-93c6-ac05089480bf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:59
bf0206dd-90b7-4c61-9700-24c24df28894	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3303.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:59
d0bc760a-dbea-46c5-8629-91d8cc079f3d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:07
146a3d14-b627-45a1-87fd-1304ed8903ee	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3313.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
1f8111a2-54a0-4dfb-8443-b3147009554a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:01:13
079ceccb-79b7-4760-84f5-0a690f46c1c4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3388.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
2fed4852-7c58-4dba-a4af-016de894de00	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
9a1a9e32-ac0d-4ef6-be37-b21c58e166a0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3376.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
ae5966d7-c011-4396-9690-d5128e1f9b8f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:17
e939088d-4f2e-4a4c-8eb4-140db324f93d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3379.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
101df74b-5207-4b20-a51e-5a6236ce7e83	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3410.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:52
a1e72e10-2c9b-4757-a913-26c0c5c4c488	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:57
830bde44-4831-400a-b825-3fea0bfe674d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3423.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:57
6ab09e8a-2b00-4866-8e2c-dfe74a5fc6ec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.5%	f	1970-01-01 08:00:27
bab635e7-a616-4cf7-92d9-5d7e6c5c88a3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2395.0 lux	f	1970-01-01 08:00:27
99336697-c152-45ed-8155-2110e498ea24	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:27
84609fcf-9f8e-448c-bb31-d97d89b998bd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.5%	f	1970-01-01 08:00:32
6f072f69-52de-48bc-ac47-42691eda192f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2394.0 lux	f	1970-01-01 08:00:32
7b7b6330-8247-4ba6-8228-af91a96a2866	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:32
0441b204-fc99-4a2c-a7e1-ed9bcc8527dc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.6%	f	1970-01-01 08:00:52
31267467-22ef-4b7d-a960-b48a4f644d12	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2394.0 lux	f	1970-01-01 08:00:52
4001b0fe-3a33-49d9-ac82-dcd739e69b71	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -255.0%	f	1970-01-01 08:00:52
1328787a-c217-469e-b719-501fa1c802c1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3664.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:21
7600f13e-6c99-4e75-af32-238a104cb525	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3659.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
19a721fc-b26d-49a8-9398-b607e264ead0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:01:02
e3cf7dd1-0b7d-429c-b943-60f475cc5dc8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3145.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:02
e1ebcff8-85f4-4953-96cb-c9165830c1ba	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:01:23
f9a3ca8d-ace4-463b-b33b-3e5d8ff190f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3101.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
664ce633-6a37-452f-a2a9-095844d92867	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:01:28
8d3cb5a5-5ce9-41f0-bd57-1b8523415486	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3088.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
eafd0186-c050-4704-8e6b-bf0f29267995	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:01
3f3d96fc-4640-4f5f-8ee0-8d235b850361	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3094.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
1fdcf735-d4fe-4718-9b6a-e785d8a807be	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:06
614b5c33-211d-460f-9002-0a853bd8749b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3071.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
e360b630-4a28-4bf5-99eb-31c3d5ec0b4c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:12
118cc4d4-2cd9-411f-a143-eba83277d300	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3059.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
f9b5f868-6728-4cc8-ace8-b6249c40ed96	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.7%. Consider improving ventilation.	f	1970-01-01 08:01:13
c73c382a-4641-46fe-b6d5-64ca8a639daf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3187.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
60bbfd33-dbf6-4e00-a435-0a994b30402d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:32
820c35d7-a9da-4794-866a-b3c17332db51	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3213.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
32a5e3eb-225b-4f07-8e98-08075812d20a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:59
e024218d-b2b9-443a-a8ea-a4a4061ddbd1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3303.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:59
478d78ba-137d-4cda-abab-5288b6cb8851	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:07
352a7550-8f06-4481-ab99-1441aa9c5718	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3313.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
7b16507e-c868-46a6-9a62-3870e283dc7c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:01:13
1fce4e49-6c98-4fc2-bb94-9268a871e5d8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3388.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
60431407-4031-4d81-a856-d3f72811bcce	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
ad30d5e3-9400-4bfb-9ca7-c2d7b7a05536	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3376.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
74b30304-6e3b-408a-9f65-70a1c5e405d7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:17
65561865-f6e2-4852-b290-785b44cb15af	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3379.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
aa033e26-3f4c-4077-bbc3-1d4f16fdcee9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:57
6b700c25-2636-4a8a-8f7c-82481844c570	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3423.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:57
14e1f0e9-8b7a-49d7-8276-6c7004e0cf29	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:01:02
99bf1f0d-db33-4aa1-868b-a33e34be61e5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3433.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:02
1897b068-c71b-43b3-b83a-cd8a224ae46d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:01:07
09944c6b-bc21-4f7c-95d7-a793ee23f2e7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.6%	f	1970-01-01 08:00:57
7caa32e4-3b82-49f5-9a25-7381415b970b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2398.0 lux	f	1970-01-01 08:00:57
17c4b902-b8ab-4b01-ab16-1bcd40e123eb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:57
a25d4885-19ee-4e08-a992-67fb66368c87	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.6%	f	1970-01-01 08:01:02
6f0f5f99-30af-48c4-9afb-1e01290ba3c1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2403.0 lux	f	1970-01-01 08:01:02
c7bb90ac-a6d1-49fc-a6ce-1fb1b142e6c9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:01:02
ec8a4171-7082-42a7-b67d-ef1f30b2af15	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.6%	f	1970-01-01 08:01:07
69ecf7d0-219f-4283-a285-520ad8cc182e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2403.0 lux	f	1970-01-01 08:01:07
a7c6116f-07ff-4662-9530-18ef4adba991	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:01:07
0e9ee2e8-e2aa-4b85-8b64-4572b9cb6a6a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.6%	f	1970-01-01 08:01:13
f11e4ada-a450-47af-9e3a-acb0c12df895	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2415.0 lux	f	1970-01-01 08:01:13
cc95cdfc-7c13-42b1-bf3c-8af73fa040cb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:01:13
fef2ff59-af46-4e26-8b69-d796af6e9ced	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.7%	f	1970-01-01 08:01:18
2405b245-b6a6-41ff-bb98-ddac5f3a61af	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2411.0 lux	f	1970-01-01 08:01:18
cd43fed0-e4ca-4af6-bc4b-18091507d540	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:01:18
fc6ca8e8-81cb-4e41-a549-68bf16936313	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
c242684e-0362-4061-b1a4-a33ae18e0d6e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3033.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
c5079626-9fe9-4705-9b0f-341e6dee972e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:27
4c609700-cb22-41c9-8b59-0d5bb80796eb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3035.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
7e4d0f38-f47f-42af-b896-48e6aa3102c5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:32
053cde49-d44c-41ca-aaee-575de474db4c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3035.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
f21c1a94-b409-4148-8e24-f13aea806b83	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:37
2ad0ed0a-3a44-4f7c-a10e-255873735e12	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3018.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
89b1ed21-f3a0-4932-9b95-267ed7b99966	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
999ace05-3b44-453a-999f-3aff30510ef3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3034.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
06e32a29-8767-4241-a4eb-77f86e3019f2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
f9e1f8f1-510d-47d1-8662-e0547eee28e2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3027.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
e97b43d1-6f2d-4b3a-9865-8924218d9480	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:06
d869b477-3db7-447d-954f-f31b920414fa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3040.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
12750a94-433b-46a6-808f-5f6b946198e8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:12
89382f0e-518a-4cc9-a412-beffb877175f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3033.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
bbba86f8-2b70-4d1d-b482-e5d53f97b20c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:17
a52fa84f-984f-49a4-b277-88d03271602e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3037.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
8fb7ef6a-b13d-4773-a496-11d7788e3483	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:22
60eb8807-93ff-4a78-be1c-578ae9ee136e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3003.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
ff4a99aa-eefe-4a94-aeeb-de3c9ba4fcb6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:27
19fd0213-b8cd-4c35-86d6-88c762b5f6d2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3002.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
22a329bd-c0f5-4a0e-835f-614ed2eb9e85	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:32
4633393b-4f8e-4c10-861e-17b3c6af8e26	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3009.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
8cbb3067-aa56-4397-b8fb-343cb20fb591	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:37
61cdcf11-6261-4a24-8c5c-8ee05b00f590	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 2994.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
4c276cf9-0df8-4ece-adb8-ce7e1358e2cf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:42
2cb757e7-1cc1-430c-963c-373ee4b32940	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3011.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
be9068e5-cbe8-4903-b81f-bb7055e769a2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:01
b54dd1ed-19ba-448b-a6fd-1c960b71d4b7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.6%	f	1970-01-01 08:00:57
3f4d5f73-34ee-403d-a689-2dd1de4cd84b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2398.0 lux	f	1970-01-01 08:00:57
e8a8a0f2-a301-4055-973c-ed1ab1faa805	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:57
e0fafd79-d263-489d-a2cf-62fda7454213	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.6%	f	1970-01-01 08:01:02
6546d481-8bab-4492-b403-add7aa43a928	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2403.0 lux	f	1970-01-01 08:01:02
6e5a14c6-372d-4b41-9d9f-07a34cc40d20	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:01:02
3e1dd247-a0f9-47bf-82e4-06a012e5b9f8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.6%	f	1970-01-01 08:01:07
c4844a21-68ab-46ee-b962-02a886c9c2ae	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2403.0 lux	f	1970-01-01 08:01:07
3c28eb81-978b-4087-907d-b2bb80d29516	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:01:07
77f63475-57fa-4411-a458-5baa3213abae	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.6%	f	1970-01-01 08:01:13
461e6e14-065a-40bd-9d79-70efeaa60419	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2415.0 lux	f	1970-01-01 08:01:13
4276cd39-7fcb-49c2-a9a8-1ae0c1c122a1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:01:13
ad27348d-e387-42fa-bbc9-36e7a2c8237f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.7%	f	1970-01-01 08:01:18
b77b0c0f-fe67-496a-a86f-4ac45636e151	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2411.0 lux	f	1970-01-01 08:01:18
a17768ed-436b-43b4-8499-5ed8f4ef647d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:01:18
c6eac242-3716-4c9e-b269-c262a76f59bf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
f740b778-a065-491a-8f59-bd8afd10a92f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3033.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
1cdf8e7f-a54c-4bdf-ba69-c5eb6f6c4faf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:27
2995419f-ae78-4aac-b4f8-8c179dd43358	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3035.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
9ac6ceee-b351-4cf2-adb2-5662ba85aba7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:32
7966312f-d669-4013-b975-98e7311c1050	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3035.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
fb9fe478-50fd-42d4-b800-fbbcf99d4c98	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:37
371f1f04-d364-4580-bae2-dff18812e7e0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3018.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
0d75d81b-101b-4aa1-adf9-edff3cd9246e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
234ce2d5-e999-4fb7-8d9f-ec32ec4eb945	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3034.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
3b33c465-d19b-4960-8403-1deba60f783c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
9c3d4a6f-7d2f-4a2c-9202-682884fef3fa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3027.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
1edadec2-f270-4851-9042-bcacc5d7109e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:06
734feece-e729-424c-8552-69e644befca1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3040.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
a8d4e5de-3392-43e1-838c-302b9e305ab3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:12
54eb4076-eae1-4065-97b8-e932bf126c4d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3033.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
d760dafd-19af-4ff1-ab77-8227027eec4e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:17
fdaf5f12-cd63-4272-be8a-02811161a76e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3037.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
129863bf-e6b8-4581-9884-bce7f3bb40a2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:22
ec278ce7-0057-476f-adb6-2ba6bb923d21	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3003.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
a41311ba-3938-4998-964b-2f3e3c587acf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:27
f3f9368c-0c76-4988-b2bc-df34ddbd70ca	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3002.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
acdc85a9-32ea-480e-8c1b-a8be4666fc74	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:32
06052e89-9db9-4631-9334-2520df46da7b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3009.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
267a82e8-2270-40aa-9022-479ac813f70a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:37
7ef861c0-820a-44be-b1f7-55a241b59e17	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 2994.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
c5d5bb3c-196c-44b9-956c-0b7b10e9afdd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:42
567301fa-7b1c-438f-83b2-840ac599062d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3011.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
f7afd92b-c07b-4575-94c0-5cce0d4a03f1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:01
9a4f651a-b141-48ed-8d3b-971a84dd2670	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Action turn_off	Device led set to off	f	2025-04-27 06:45:34.544166
05fa6b85-2f7f-4302-af1f-611a012dad8b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3024.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
bbe405ac-bd87-490a-84e0-a59a3d2b3f63	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:07
03b2d9db-457a-42eb-ba5a-cf8a653b0aeb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3022.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
2f6c8cc9-b883-4dbc-a4d7-14d62e6ae6b8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:12
6391acd6-c551-4e9b-b95c-f417e3c03c64	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3022.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
ee7b0090-df30-49d3-bdf7-97b98440591f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:17
ade86643-8671-4b93-bf40-b54af6a5c911	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3037.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
0f0fe4c4-7aa8-4793-a2bd-0eaf6c303795	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:22
cc560be6-5a96-449e-b514-062ca17d1aa9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3035.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
485b3648-3893-4750-8393-42e296292c85	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:27
0fe6d84b-216f-43ac-a6fe-9ba7ef10ba73	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3040.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
16082757-3361-435b-8615-6992c290ca3d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.7%. Consider improving ventilation.	f	1970-01-01 08:01:13
8a849504-7113-40f8-8737-a97b20339bdb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3187.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
d6ee5d95-d799-46ee-909d-160a0b8c18c9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:58
479fa03b-c532-4a94-9966-ba7a2b50c0ea	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3249.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
1f32e9fd-def4-469e-9013-7626b4df213f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:03
4119a7c3-ed28-4b75-b009-90df4a4166dc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3259.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
857c369a-9222-45b7-a17c-553f33558453	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:01
205bbf68-ab52-4a0d-a64e-f6db282c326c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3253.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
2ec234ac-33c8-4ab2-96a7-5841a384efbc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:06
e5855966-2ddb-48fe-8fa5-3245034767a9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3248.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
cdd3574f-390b-40b2-b7c9-d428a7e48ac4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:12
f2348657-b351-44ec-9b95-b4b9da07e02b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3264.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
04cb34bc-e7d8-4dcf-918b-ebc69c93770c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:17
e7064007-23ba-4628-9057-46d0e501584a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3234.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
5c643e43-b269-4b1d-8798-4d8c34345d2c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:22
711b2373-0d6c-4a12-b8e2-d6d6d3db2310	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3270.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
a1a8bc87-97b0-4ef5-9282-1fa4620bebfb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:27
9afd56be-3ced-4a1d-83cd-8e8493f084db	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3258.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
23acdac7-debf-46b8-8c94-eb682017748f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:32
128d2e52-adf8-48f1-9afd-563cdb66e735	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3257.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
cc77172d-74c2-43e5-818f-9492ebc7f79e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:37
40197699-2a98-4861-bd12-6eb243e49547	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3183.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
668ffad9-ae5c-4abb-abc9-884372b1974c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:04
f99085f2-3c8b-4918-b771-2465aeb2769e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3306.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:04
d49ea196-e89a-4f16-8d8d-5e0ab5a021e6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:09
26512fee-e360-4d51-8531-53e12b3411c6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3318.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:09
2456a736-7a08-4f23-ab31-1c439797bcd0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:14
5aed3fce-4a9a-40ae-8dc1-406ff61dc92d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3306.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:14
505a0512-aaba-4cda-97f1-cfcf1eec5fd3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:19
9c8711d8-11fd-45e8-850b-a08914135c08	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to off	f	2025-04-27 06:45:34
9f559db1-96ef-4eb3-8379-b17bd3a2b539	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3024.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
ff5160e1-2cb8-43d3-a26b-ddb89055454f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:07
346f7f9b-b9ba-4686-875e-837776564fce	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3022.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
e0df944e-ebab-4bf8-a007-4354ea18b94c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:12
3e83eb3c-70ce-4a1c-a7da-89995308f545	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3022.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
6dea4c69-9264-4d1e-bebb-414228772bf6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:17
d67ba2ee-dfe8-45ae-a54b-a439bcf16256	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3037.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
2722252f-cb85-439e-b061-de6d97d4a0bb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:22
53cd04f4-ce15-4795-9887-9986e4e91cc7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3035.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
1727ec56-39dc-4486-92eb-5504995206f4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:27
1925185b-6d29-418a-ad36-280045882838	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3040.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
126443b4-b8fc-4952-9b82-627e11c65566	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.7%. Consider improving ventilation.	f	1970-01-01 08:01:23
d09b6ce0-e6f8-4ca5-931a-d5afdc4297c4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3184.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
d59ce76a-1baa-4376-a97e-021588777311	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3184.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
da03cac5-e76e-4e23-89e2-519ac824f901	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:58
c0ba9370-4478-4df4-b55f-f4c5760c1e31	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3249.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
3105e7e0-44f9-40dd-8c99-37751911be46	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:03
bb341ef7-1a58-4529-851e-225a91e3dd09	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3259.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
288f51ef-b08f-422d-9db4-b23abc3d0380	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:01
5043ec61-1ec8-43aa-b45b-adab2f1a64bd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3253.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
efd3767f-faad-46cd-9f79-7e9272a8adf5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:06
50f573c9-bc76-43e9-9da6-0920e6291637	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3248.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
7b2fced3-a8fd-4ac6-baf2-45a18c808e49	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:12
3a987156-8443-4077-98c7-81a23740e989	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3264.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
878e712b-f2c0-47ca-8eba-e8322586fa1e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:17
6a0213bf-a392-47d7-94d3-6d7793b3368e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3234.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
82063a01-12fb-4a9e-b4a9-183c1890d216	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:22
2d28f0ff-f1ff-499d-bb66-1900a4ca18c8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3270.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
ced9758a-5a26-4fc5-81cd-9211372b2822	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:27
5b9a6108-e671-468c-a547-9fddc735ba0b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3258.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
92747196-7114-43c2-be0b-462c2bc3878e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:32
02e0cc1d-9a04-4284-8d62-be19727a5422	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3257.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
1369657c-c09d-47fa-a48a-a9e7e0eff0d3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:37
a6bf380a-4ff3-46b4-8272-87ab7e571cd9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3183.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
417a6071-893b-4ea0-a46d-227aa7018d2b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:04
b38e555a-96c3-4e9b-95cd-ff1174a6923f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3306.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:04
6657d555-db68-495e-8424-d91415fa46a3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:09
28e966ad-df1f-4b23-98ab-465205fea06e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3318.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:09
6a85f378-d7ef-4b83-b26a-4f68b2b27dbd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:14
6a393017-3be0-4cbf-9aac-ea85d4120c43	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:12
40c849c7-edef-4099-a73f-36d789afb069	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to off	f	2025-04-27 06:45:34
385f1bb8-a55f-46c4-a1b8-977bceabf8da	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:32
93e6e33c-f6bb-436c-a7e5-761f23ea454f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3056.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
f4695b3c-6954-487f-9cbd-d3f1595279b5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:37
cbac733d-8ff9-4fb7-99f6-ec5e1d3fd951	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3057.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
ddf0d19a-073a-461e-86bc-2f5e4257748c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:57
bb2caa7e-76c3-4abe-8c12-5564cb17039a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3040.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:57
bb528da2-3c4b-4020-be21-64c74f506b1f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
ceb0a9a5-4439-4ee5-a563-03ca08b61b8f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3035.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
8db20d3f-82e1-4526-8a80-e1a593c4f73a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:07
5d74424a-6112-4c73-b5b8-1d80b8ca2151	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3030.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
de64d02b-eb67-405c-a987-78f6599af5da	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
a8eb7850-b802-4af2-a929-b374faa7e81b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3041.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
856daf26-c04e-46c7-ac9a-ce16c730e12b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:17
0ebd8a5b-e2ca-4665-8b46-2db844bf73aa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3051.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
4008256d-cd19-408e-ab10-2827d4552ad1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
eec3cffb-e297-4819-bc54-d737463e1fc2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3063.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
e26c0e84-7117-45e8-9cc2-957579090697	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:27
f6d884f1-291f-4880-b5f8-f9b802538e7a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3065.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
9658216c-b490-47e9-98d7-db1a747cea1f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:32
44e7e1f7-f449-4cf3-912a-d1a9a0b2b675	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3088.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
3a96834d-2ca4-4eab-ac63-5af1baca3ae2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:37
57f6caa7-b73c-401b-8f4e-aecb6aa6e2bd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3102.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
12339347-9d34-466d-ae10-58467c9a2f39	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:42
a9e4b78f-dcf6-4e7d-afd2-743e731ee62b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3111.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
df26ee10-3b58-4003-8564-7029466ce98a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:48
7b3cfa62-d8e6-4ce2-8c26-2d8c22079126	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3147.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:48
4c869884-a586-482d-8183-450805902836	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:53
721e7939-c85e-4427-bcc2-65ce1525f25a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3152.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
82a40156-3542-42a0-9426-df76c95efdd4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:58
334ddde3-7154-43ec-a5cb-a22429231b52	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3152.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
05c349bc-e925-4542-a0e6-2718d9182ff1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:01:03
efd77f27-510d-45e7-bce0-10b8c8d968c7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3155.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
9a3b608a-e24f-42a3-9955-a3f48b0bc427	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:01:08
d651ef76-c954-49fe-b356-9c99fde3fac8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3151.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
cd1126e4-aa44-451f-823c-ab75600097d6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:02
1d12f01a-8c18-4895-8335-a2fa38dbf164	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3135.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
c5273bb6-10b9-40cc-9e13-b1c72a124846	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:07
0ffc4ab8-4e8d-4079-b3c6-d6a8ce4219e7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3131.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
68f4d16d-851f-4c9a-ae34-498e67182d98	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
379015bc-1f5c-4063-b1ab-664b1df8c593	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3135.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
23eb5c45-f579-41f0-b9a1-ce85ef857753	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:32
8ad383d6-2c84-43e0-a63e-9677b609a581	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3056.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
d71abe89-336a-49ac-b16d-cb549b31b360	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:37
24ceb4ec-09ad-4680-89c3-a47cbbc2bd07	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3057.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
b1d7a304-75f5-4f38-b9f8-8cade7547ea6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:57
e0ede9f2-6cff-4165-a5de-4b345561200d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3040.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:57
96224b86-1303-4608-8c59-e4407ecbb936	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
66f1f5c4-b4e4-4427-8f96-80459a8a4b8d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3035.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
57296140-6fbd-44da-b10e-3b51e05df1c1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:07
4a2567c7-de8b-4957-bbe9-01f6e5d4107a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3030.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
0ad2f352-53ea-4052-ae63-e765de246d86	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
86545f9d-bb30-4e5f-812a-c9482d2655bc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3041.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
39d11bc8-40d4-4e03-a2f4-6f9e10d2f6ed	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:17
371575b9-0b22-496a-8d25-ede84accd9cd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3051.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
276ac1f4-ec0b-4892-a6a9-64f7aab1cd70	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
e70fe4e6-0f86-4186-8253-e99da909ece3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3063.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
8db3bebc-07a5-4654-807f-312fc2965c85	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:27
6166add8-64cf-440f-8376-27a2d669732c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3065.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
b3a031f8-8b2c-4f91-a840-43d4639ee1ad	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:32
4d6d8db8-e385-4d15-8618-a68d1eb5f1f3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3088.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
a31191fc-c833-419f-b964-4dd66008a082	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:37
a9626cec-87ee-4c60-b801-43609a98e4ec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3102.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
30fe5fda-5ce1-411f-9790-f702368cdc17	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:42
eecc588d-cb37-4333-aa54-23e0aa97ec22	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3111.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
5ee2ad48-53af-4a48-8bae-9d9ba37900b2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:48
75255d83-72ac-4694-91ee-4673e87fc09b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3147.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:48
b086e96d-dc93-4307-aaed-20d0a03458e8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:53
566681c5-c2ec-44f6-b996-11bdf701778e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3152.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
2f97f589-c903-4a14-a02b-13f1e1162eab	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:58
bfcbeb30-1d78-4095-a08f-8272e3c1e1fa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3152.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
38b91472-d3de-4695-9310-1c430d9e911e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:01:03
0eb657d3-349a-4411-9e7b-8cfc11a7d6b9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3155.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
f52a8e68-c73d-4c47-81e4-0c85ed8bdef8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:01:08
87290bc1-e36f-4ef1-a4b7-5ef9d45ab144	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3151.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
3fb19179-f62c-4632-9fd1-cb2cacf5c4ca	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:02
50bde633-e909-42b4-989a-c92a208e6bb4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3135.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
c355c10e-2366-41b3-9b1b-0f9d859a00b7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:07
187c782d-a128-40d5-a913-0616dc40de87	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3131.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
5c57be08-b076-467f-803b-f27a3d7e3dd6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
cfbb0cac-3f95-4b00-b5ef-741d96bc60b1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3135.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
ea794d12-39de-4cb9-9b6f-d4392cd470e6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Action turn_off	Device led set to off	f	2025-04-27 07:48:03.950316
dddbf639-9201-4cc0-9252-1bb98ffa4ec2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:17
3334abce-cf45-42b1-afe5-9241bceb32ea	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3115.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
2d5be80f-2128-4075-a1a2-cf28456a49f5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.7%. Consider improving ventilation.	f	1970-01-01 08:01:23
a65b473a-d674-4d44-9400-224229a7ef15	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:42
986582a3-5b8f-4348-9866-354db023c606	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3280.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
d3e140c5-e212-4bd3-a73d-d22035539d37	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3306.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:14
d733a1a1-3cf2-4232-a7be-2e40591ad9d3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:19
1a017357-8167-4097-983a-e9a5b8096281	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3319.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:19
ce739d1c-f9f1-4c1d-a4c8-3bf6f28a040a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:24
f3284fb6-8f7c-4546-b37f-145140697ec3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3307.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:24
af25a038-fded-418f-8ad1-8d3245cf52fb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:29
3315587d-7d27-4dc6-935d-e5645857b441	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3299.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:29
372243d5-5f1f-4ef0-8ac5-5e467428d7d5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:01
94b53182-ba91-47dc-b764-baa7c1b05639	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3317.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
558082bc-af1d-4b5a-847c-0118aaa22071	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:06
e57541e5-f564-4636-9e69-20c928b58667	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3286.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
5f746184-6ff2-4fab-885c-4619ff9f3fa7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:12
fe7c5df7-8bea-4e00-bb7c-8df00062b71e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3312.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
6a38e314-3b20-472a-afc7-32a6d6136beb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:17
d4b5e583-96a6-406d-8be2-ed0272612047	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3312.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
3b30181a-8ec3-4b0e-8c05-246ce079c0fa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:12
83ecbcf4-7979-4256-9f0a-3499683d3446	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3328.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
0327c0f7-552a-46a2-b1df-40394ff87442	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:01:33
34884ea4-feb7-4f35-bad5-c24787484aff	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3373.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
404e52f6-c7b2-4fdb-b29c-318f441d1c3a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:01:38
519124b7-5074-49f9-8dca-9fb09cd13974	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3363.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:38
237a842e-3f42-4e38-908a-fe7d2a4cf63b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:01:43
65a16e19-d125-4924-a3ab-68552b0005d2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3350.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:43
c7032dec-4303-48fe-b87f-52dc51d41f23	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:01:48
f563b787-e0af-442f-b426-0d01a3298c73	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3374.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:48
ec33354b-6f24-4e7b-8bdb-935f95633664	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:27
14d1c5aa-15be-4a72-afae-7a45fc4f55b7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3383.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
f8bac64e-7384-4843-8a51-2a792ee6907c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
1ef3bb72-7a3e-439d-94fa-7d3216c842b4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3395.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
d24958d4-84a1-44d7-9773-66bf321c37c8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:27
55777f57-766f-41f7-8661-553a352e5bdd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3390.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
3c638e03-776a-4147-ae28-7ad34891e4ac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:01:02
ddee9aba-55ba-422c-875e-1d03bc683aaa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3433.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:02
bfd5554c-bfa1-41bf-a8c8-4e644f4237be	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:01:07
eb5478b8-fbe5-4ede-bcb3-7ee78065fe18	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3419.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:07
3773d559-92f5-4e5f-8036-4b4d8efa7cf0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to off	f	2025-04-27 07:48:03
f5a47aca-d2f7-4591-beb5-e995937f7900	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:17
e6102322-b6fe-42f4-a589-1c83d15a5cdd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3115.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
293f0761-3877-4d30-9fc9-0cf41f14dad3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.7%. Consider improving ventilation.	f	1970-01-01 08:01:28
32e4b8f0-295e-45bc-bf35-db8534028ce8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3184.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
2eb993bd-6a16-4a20-a333-01d8699313bf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:01
ce308648-7f70-4a94-b244-9d7b1f104cff	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3194.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
36baf7ab-745f-476a-a3ef-7ca9a4b59388	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:42
3fc21af7-e40f-4ea0-abe5-8f13595af0bd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3280.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
175d256b-c27b-40ac-ad3a-c6fb4a21cf5c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3319.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:19
d48055de-46b1-4b72-aa93-e44664bef7e1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:24
996dad33-8024-4468-965a-27e8b4c24780	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3307.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:24
4a1e71f0-6bdd-432b-9798-c99f1d01e4bf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:29
c5dff8c7-fca2-40c1-871a-4b477c3199a4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3299.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:29
f9ee85fe-ef92-44b5-b5c0-51e4956ddfb9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:01
c232557e-4913-43c7-8d86-18315870f1ec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3317.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
4526bb00-fd6d-4806-869d-f78849b3c54e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:06
453fe3bd-5faf-4b39-9bf1-7785d8d50075	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3286.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
16c640aa-5bec-4287-bbda-bf36f2f706a1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:12
46436993-21f7-4833-904e-af8b186ec047	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3312.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
ba04ebb7-1b97-4e1c-82cd-946571bb435a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:17
1a3d3657-3516-422a-b41b-401543eaf0f5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3312.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
c42aebef-da36-475b-babf-d4ed88e51deb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3328.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
6a88a607-9322-452b-bdb4-d2fc36c65535	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:01:33
3100f9d3-4174-498e-aa5b-638bba47439d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3373.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
17c95a0e-696c-4813-8e01-f770083aac28	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:01:38
72a4c66e-160b-4162-ad99-c9dd950663c3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3363.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:38
f5b6a064-aeb6-457e-accd-6023b5e3af91	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:01:43
5249c377-43c0-44d1-a5c6-ded28f4900af	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3350.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:43
906b5b54-2ca5-4930-819f-0326143a007f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:01:48
e2ea2961-8250-4bab-bba5-1e9ea5f972dc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3374.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:48
02524573-2eb0-4995-9760-7c5842e1709e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:27
f7875472-f345-45cf-a87e-b5dcafc373ea	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3383.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
2d91995d-7e78-465b-80fe-4432bcef6f85	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
59d2dcd4-7669-4e70-8c30-9794cc7b5822	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3395.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
c73537d4-7e21-4c32-b8c7-d0a060cab2e8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:27
113a5e7a-097e-47a5-b130-14ddd460bc84	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3390.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
8a2d540d-e0d2-4899-b915-7d7e17f31edf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3419.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:07
1004a65c-3c32-4b38-974e-b6a47c2a6173	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:01:13
699566aa-b962-4fa4-92e5-4ae5a277748f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3423.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
b3abe5ca-32d6-48bb-9388-5f4fe9fcddb3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:18
8c08cb53-9cfd-4aa4-bf57-74acd1d4eb7e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
25c33ae8-72cb-4ca6-bb0c-03ab88c1f51e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3112.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
9564995a-9352-49b4-b94c-bf54fdc85629	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:27
c88c3ad1-a961-47f0-8b5f-992828cdd1b7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3123.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
96c9eb21-14b8-4fdf-9e21-e31b9c7a9719	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:32
9eff3f0a-9731-4f1c-bd1d-72959b4ff3ba	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3117.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
419b175c-9f98-4241-9e16-a5966e9ccc71	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:01
40820d58-b065-44ad-a6fa-ddd4c0717756	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3120.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
ea30f147-b879-406d-b5f6-1e773a8c0831	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:02
75b82772-c639-4582-bf2d-8126054d8e98	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3141.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
d0648236-ebf1-4a5d-a8da-d7a7896b91cb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:07
af0e22fb-12a6-4e86-9b5f-9e1c003f3ec1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3143.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
2245157c-3047-441c-9134-4ca9bc628f25	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:12
db580b5e-e6a5-4903-a016-8b2f4c15591c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3147.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
f9e3e5a5-2abd-4640-bffc-8485c2c2029f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:17
66bcb747-9eac-45b0-a53f-ccc30d121afd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3147.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
2a9c0fab-7108-4524-90fa-f73198628a06	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:22
00eeee2d-80d3-4aa2-b806-dd37d89a5f8b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3133.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
94c194c0-4367-49b1-b1e2-5fc2fd847d5d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:27
a20f80b2-0b79-4ea4-9b03-6e0f2b3e39f3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3143.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
1573d4b8-3802-4ccb-ab7a-c9581c851416	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:32
b6b2b474-33bd-42e0-a991-0677d4facd67	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3147.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
481b4280-9a35-408e-b901-0c0b74a02eb0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:37
5ba3bb01-300c-4396-a73f-19fc3203498c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3143.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
4f35f5bc-442d-45c9-8f73-c790c2b32ea9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:42
eb2bcea3-ce09-447e-93d3-0c697b4d7a6a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3155.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
da0e6330-04c3-4626-8fe0-258b0799b512	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
d557c6d5-f336-4998-be34-2ca8853e0b56	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3168.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
338ac384-b528-4683-89f2-e94642610333	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:06
76fa764e-0605-4c7f-a173-1d1ec81a2a8f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3167.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
5d77544f-43d1-40c7-8fe1-fb3acf586e58	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
7d534418-479e-4e0f-9d8c-04d9f28f86c3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3153.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
2af5c4c8-f37f-4b82-a240-9b5c0b7d3a30	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:17
d1f0831d-dcb4-4230-aaae-e9b24db61e85	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3162.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
3d38adac-38e4-4644-b391-93819cefc77b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
234e0614-ff92-4345-adda-c1d9b27d3b73	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3151.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
506b60eb-5403-4732-bfe0-698cad47c7a0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:27
615df005-a2ea-4c44-bccd-bbbee8d01801	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3180.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
afd9b7cb-32a7-45ae-aa1a-9e468a4d1e3b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:32
4d03ad33-3093-438a-bae3-cfe7dd9df5ba	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3177.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
cb614d88-f3fe-49b5-94b9-058898c1110e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to on	f	2025-04-27 10:18:50
f594095e-b80b-4be2-9eac-bba5573120e7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
20283879-3c4b-4c6d-b578-32df94ab5a77	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3112.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
7afbf0cc-4a22-4d45-9f9b-16fd453955d6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:27
20da85d1-4ec6-4507-9be1-0b31af1dc0a2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3123.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
83a221eb-617e-41f6-b372-1cffabb88287	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:32
62e6259e-707d-4e5f-b966-4edfe56856b3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3117.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
71549818-22f1-4d30-8a21-1d54c9d19ad9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:01
49cc00c8-9e80-49d1-99d1-e42d3a64bfac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3120.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
037e408f-b0a9-42aa-b93f-d6a8e2538c5c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:02
3cd67043-c395-411b-8254-e403936b867f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3141.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
ba79ab7d-a93d-42b9-a28e-9bab22159158	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:07
59331b58-85cc-46ad-94b8-ee1c2e25df36	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3143.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
7b9ad373-4146-41f0-a70d-d15616f3a387	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:12
e8e1e831-de62-451e-97c5-a923c417cd77	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3147.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
55b5a62a-310a-447f-b399-52c5c7c014ad	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:17
41a34c9a-b38d-4490-8fe5-68387d8a2e41	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3147.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
59a03c70-09bf-4ea2-8659-8232d0aa80af	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:22
76d48780-21f1-4347-a369-35914885a18f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3133.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
09e31712-ec13-49e5-95b2-1218e01b471a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:27
9021edae-643d-4e5c-8927-c9b707e82559	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3143.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
2bc944fd-38e5-490e-9be1-fea4ae5f0056	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:32
debf16ef-869c-4b45-a240-81e521513ef7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3147.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
cd32be80-c495-4144-ad26-54088584930b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:37
7cd00f20-fbc3-4b85-bdec-c7acf26dd9b6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3143.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
b7ca3ae8-ad74-4fc1-9704-9a0931dd2162	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:42
7a7f9f0c-8a30-4618-a95f-e8238720bae6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3155.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
91e286ff-df0c-48c2-8004-1179693f9e92	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
09e08422-1e8f-4f71-a95c-00ff635d441b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3168.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
0226422e-f7c0-4c2f-8c81-320dc0b8ff98	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:06
173cb478-767b-44b4-9253-47df742e7b86	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3167.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
eebd37b1-07e9-4c7c-b1c7-e3b2a2b0bfa0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
9c27d1a1-cd6f-4cd3-9ffc-7777bb9537ff	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3153.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
d68703db-3c1e-40b0-a413-df709f9bdd97	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:17
08105019-81dd-42d6-b66c-cf902b23abab	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3162.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
bcbf692d-2278-4cf1-8c2f-fa4a2e66f199	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
cd9c806d-7e26-4134-92d1-a203129b2873	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3151.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
9c816e14-ae69-42c3-8323-404ae8e309a7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:27
8cae60de-1930-4d55-8c7b-d8bd0239b8fa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3180.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
7943905c-0b23-42d7-a494-01605c732e7c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:32
1d674b18-084b-485f-b63f-d78e84d3d844	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3177.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
43502120-cc3d-4a8b-aa53-6498c3eaa672	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device fan: Action turn_off	Device fan set to off	f	2025-04-27 10:19:15.992741
20d2904b-c074-4b2c-b268-6f8955a8ec03	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:52
e5617d68-cd30-4f74-863b-0caafcafc0f1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3178.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:52
d71b40e9-81cf-4bc2-9cca-c63e366c4489	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:57
70bdcee2-e55b-4309-ba3e-f54f612779dc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3183.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:57
97e41509-80cf-41ae-bd53-594ff6f0e41a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.7%. Consider improving ventilation.	f	1970-01-01 08:01:28
4af30f2e-8a34-4353-bc5c-ebd8b03f276a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3184.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
8cf2b97b-2e6b-41d9-bf00-ac9b7e8bf4d0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:01
34fa3afb-8bb8-45e2-9e1f-8ecb9119ea64	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3194.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
6747f0cb-8922-4ba6-970a-2482711197bb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:53
d28636ef-449e-4f39-ba51-388bae40c60b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3291.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
c61962b8-1f8b-4a27-be5c-d87952f8b8c7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:22
427f7883-2f69-4c4d-bb71-2af1192bdd1f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3306.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
26a71a3c-cc04-4b01-8e5c-64ed08a08c2b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:27
f8a5b0d5-7e44-40e2-b4a7-7a4266575090	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3312.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
9e7cd094-3c00-49a4-ad3e-0eb46c6f7bf2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:32
08efb673-3ca3-46d4-82d7-36f23a13666c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3334.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
acdcb737-e789-4895-966e-84a53a2ec4ac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:17
da9f6624-6993-44c4-b397-4befa96c3d5a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3319.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
2f681e01-a3d1-4d36-a067-a7e4d60e46cb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:22
2c6c75b8-a7b1-42ea-8341-6e8a7d937599	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3325.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
9ce14604-5b68-412c-b856-ecbe7ec2fcec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:27
c7de0870-c72e-4dbd-8c36-12a1e6172d9d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3323.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
c8cb1c9b-d7b0-4d5a-91e2-4ee84f0ddfde	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:32
c9aa1847-ae1b-444e-91d4-206c53228514	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3335.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
fce9c9b5-aa70-4a78-9758-6206648ae37e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:37
0bf94dc3-8146-4b75-be8d-6e5a28bbf9f8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3354.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
73b3e5e8-e9ac-4046-95bf-0c41914f6cbf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:42
ad3d906e-8bbd-4d48-a783-32de2f394669	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3339.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
c2836e2b-c589-4142-8d88-6285a6535364	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:47
6b877bf2-e59d-4580-91bf-a2172f7adc3e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3359.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
7c0cf6bd-55c5-41e8-ba3a-4a29c407b699	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:53
1ea8d0a9-2b29-4800-9b3e-cb94e484ff1e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3341.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
b3b3447c-db9e-4607-814c-777564b43ee6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
68b7f0d8-3ce5-40f4-8294-0c8f1ae6e00b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3354.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
5b50e052-2831-481b-b284-042ba4307f61	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:06
4113e94d-3868-4358-bee7-481f46bbfec0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3344.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
6d7d20ba-44c9-403a-85f1-0ef0fd030799	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
82f5bbb2-3a93-4599-929e-5ab166385a25	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3361.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
9d400950-dc95-4cd9-8e89-cbaf2c77240c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:17
4708c174-327b-4813-b366-a42efe4c9e41	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3346.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
c44a772e-807f-4d21-b23e-9cf3b7363442	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device fan: Status Changed	Device fan set to off	f	2025-04-27 10:19:15
4b102571-d742-44ec-aec9-4588303c6b4c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:52
3597ad94-5f4c-4dec-a3b8-da82cd57c94c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3178.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:52
aa344337-77c8-4512-8b17-685ae21a9ae4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:57
d8fd6832-816d-450d-9626-acd794426945	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3183.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:57
5e8bd178-af60-44af-a54f-7e991bf67d45	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:06
7f88f6a1-6df6-4bdb-b563-f4c74f09028b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3199.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
559b26ce-5f6f-417b-a52a-fcc560849986	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:53
0d537db5-b34f-4cbb-a736-326b7c6391cd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3291.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
a85c8c88-d70b-4d26-8727-15ee98ee1fff	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:22
1ac75734-01c5-4603-b35d-ec587ec02876	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3306.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
00078a41-a55f-4ec6-91bb-1c5c5e4200b9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:27
a46b16df-c0b6-47db-b95a-999d2ea8c251	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3312.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
a945ecb4-5366-427d-81ef-93aff99227f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:32
71078e26-21a9-4032-b1a0-32f4a36f40fd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3334.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
18d0f714-2dd1-430f-a834-5b81eb965949	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:17
afcdb685-44f1-46f0-8299-d965ae033efc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3319.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
6f84099c-9f45-4b12-9f96-e483b0111d17	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:22
8c9bc813-902d-432e-b778-df12e8afbb9c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3325.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
d382d2c5-e612-42d4-81dd-5717bf3431e1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:27
308e5103-c0c0-4096-b14b-7cf37f93c45b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3323.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
f875e77e-66c3-486b-85b2-5b9ce30e8094	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:32
6bdeb28a-414d-4bb7-a890-3d9d6593f28a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3335.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
8a53b4d2-0876-49be-9eb7-67e6664751b5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:37
071bb676-d4e9-4b06-9341-3a616dd230bc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3354.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
cda6d121-2647-46db-b93a-2f92452cc8a4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:42
c16e2aaf-5c71-49a9-9e1b-0f1fd4d474d7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3339.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
ae25c759-5cb0-4e57-b507-1fb1d48a2155	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:47
00577466-7e01-4a83-b1f1-8354240d049e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3359.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
56fa7cdb-fa73-4e21-9894-66d6df3a4243	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:53
bd08c7bb-582c-43d0-8408-9742c4cba404	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3341.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
567a3871-9afb-4ef0-bfa7-7aad761357bc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
8f689065-8ec6-40f6-aa50-ba14dccf3d5e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3354.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
4074d399-fe13-4563-91df-f6f82fe0b5ed	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:06
0b57be0b-31b2-4ae1-bba8-27b8d08b156a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3344.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
7fa05593-2ac0-47a2-a05e-4a2dc3ef3cb1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
24ac82cb-7dba-4749-9079-a05e506f1a31	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3361.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
caf1cb59-cbbc-4b71-8d5f-15c818827ffb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:17
1e622ee1-bd96-4321-8fd3-359646f46f24	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3346.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
89722982-1dfb-4885-a1af-9a76782acd77	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
0415d393-f1ae-43fb-82ae-d7b893fb3b69	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3361.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
34c2932a-bde3-49da-bdb1-dd50dab52769	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device fan: Status Changed	Device fan set to off	f	2025-04-27 10:19:15
39cdfb04-1c54-49f9-9c41-ed9878d20cad	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:02
9c8406dd-8426-47b7-a2d5-16ebafe96ee8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3185.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:02
d84d29f5-19fa-4ee9-aaba-a889457e70c5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:06
16aab1c5-e673-481c-98b3-8eef7a32dd38	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3199.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
bb65c8e9-cabf-4d87-9a95-69c4a67fdabe	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:58
09728907-d483-4b1b-a491-8a9cc63d1d48	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3279.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
3c725e66-f99e-49de-a00f-dccc11d6ef15	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:03
58cc1b25-9dbe-450d-a06b-9af38920617c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3280.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
16727971-2cbd-4f80-bacb-a670ec8221bc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:08
a04c6012-1da3-45cf-b2ef-cf685942de4e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3291.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
34fadecf-3d2c-4376-8c0b-eda5f94f627c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:13
5bb1d6f7-0b92-464d-bd7c-cf815dd40a79	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3302.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
89c49fec-49cc-4bab-b166-2ace981111ea	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:18
df3907a7-96f7-4852-a778-4ac21e07b1ec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3330.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
80f63dd5-9a66-4f48-b2c2-24ff53444bf8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:23
5d8ffd63-c2a5-4910-869d-0f8d986b6f32	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3297.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
6863a5c7-b109-4e3b-ab76-827cf5911d02	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:37
5b7f1106-214a-4c79-b26b-dbc76762c6a9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3314.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
d95568ce-0775-4191-8e85-771f748d84a0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
2e79d4c2-f3f9-4e3e-b54c-794c9bd11117	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3361.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
bfae0f87-d460-4ba0-a87f-a7de66ebd43f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:27
a918284f-a461-4d1c-9df1-693b2761d03e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3362.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
7e89c22b-13a0-4841-9062-4431fcd2898a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:32
3744a727-58e4-462c-a07d-b373fb6c8d1c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3372.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
f7ab3e9a-400a-4e0c-ad58-c3c267a070f3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:37
8cacbd26-85f0-4feb-a44b-5ac61e992645	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3367.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
3486bf93-1090-4818-82d1-f6b944e207d6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:01
a914cbdb-d345-4b71-b64e-61466c911f26	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3376.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
a6c9beec-58ea-4562-aa08-d9aaaa216fc9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:06
44f22654-91a9-44b5-b666-080dac687ab7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3375.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
94256552-af95-4b0c-99c7-75d79919f514	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:32
e4fda667-a386-4893-b77f-e912f518376a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3374.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
ad790397-1c34-4d62-9888-a83ccb3e09ce	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:32
589d5eff-8ec9-4285-878c-dd34eeddc47e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3409.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
835461f0-ba8e-4293-bb33-8115b1269156	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:01:13
80b8ce4e-3e50-4cb6-89b7-d2a191f1ca20	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3423.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
286ce1e0-7685-4faa-b096-69689c26db7c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:18
5cdb5385-1831-418f-b2f9-c6290b098592	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3436.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
60b98385-b990-400f-b26b-abf51fefc44e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:23
7217f872-3ff5-4e7a-836d-154cd066c89a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3440.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
e9a04542-0b41-4ce8-9b84-941e04251acb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device fan: Action turn_on	Device fan set to on	f	2025-04-27 10:19:20.020923
14a92cd6-6dc7-4df0-944f-5df3884936c6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:02
31fd86ed-1959-492c-a2fb-93fb5619b891	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3185.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:02
f1d863de-53ec-4d1b-8bff-2db6c067cd3f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:17
3c38a3d1-3950-46d4-a09a-549dca8d44a9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3205.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
ede36a67-526f-4aaf-99ac-454bddd106d1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:58
300d012c-721c-436d-8e95-5bcd78b827e9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3279.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
9da97f00-d349-43d4-821a-f258524ad989	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:03
00860f40-ac95-40ee-bec7-10f6e3e35d05	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3280.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
15236649-caff-4630-8aeb-528d162bb52f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:08
5b48d402-1282-4406-80dd-914c33113d5e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3291.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
b129913f-7b05-4fe1-a875-c8b2e0def4ed	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:13
fea7931e-66ce-4c5e-ba95-0a8d4903f7f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3302.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
819c33b1-fae1-49c4-acba-cd33faf84321	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:18
e7a23016-d237-4796-b8e4-247a49a11e23	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3330.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
a63138d8-33bb-4ccd-87c8-78307af6f8e3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:23
d5a51059-2608-4f1e-b746-a3ad9449f3c8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3297.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
499b7069-daeb-4963-b016-e770c4560e38	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:37
c49786d4-3200-4929-ab9e-0797ef08858f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3314.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
89438f91-de9b-45fb-b645-37f7c4744e0a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:27
1c9c1d2b-dfde-44d0-8059-0ca5a39d3aa7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3362.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
1a2caed5-233a-4cc7-97d8-33369f456b2f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:32
b62a78cd-f2d0-41d9-8d44-14ddfda237ed	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3372.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
af5906af-9f12-4af3-959f-70d1f0ca4c03	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:37
aeb48242-42a9-4142-93a3-c2e461efb2a6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3367.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
8a2694e2-0fb7-4186-803a-1f694ac6f6ea	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:01
618c9bbe-5ddf-4e61-9e59-810690cd456a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3376.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
e4681afd-46c0-462f-8f38-217c58596bfb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:06
a4f7f59a-d8ef-43c9-9e61-c408fa1d5ff4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3375.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
0983b0ec-97ad-4c37-9152-3380c7c0a771	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:32
3ca21a9e-e9ba-4e28-8cb5-ab16553efaa5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3374.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
a92c1567-2042-4358-a5c4-3d514941eaee	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.9%. Consider improving ventilation.	f	1970-01-01 08:00:32
dd6585ae-e826-49a6-a026-70301b7e4665	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3409.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
fd762bb8-9f6d-41ae-a591-e789d559093b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3436.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
823e0a5b-4f78-467b-b4a4-02b99e8801e0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:23
6b140b03-91fb-4d88-a10d-fc465171d7f1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3440.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
642cc2cc-71ba-47ca-a45e-00f3062f94d7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:28
a1cb3bcd-8fb3-48e2-82f5-f973da7274e9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:28
d0ed4cd4-8c6d-4284-ac6f-7532a2aca8c6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3472.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
df06c940-0168-42df-9125-076d69fdc67d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3472.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
fc036ecf-37dd-4900-aded-f5fbfb37bd5c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:33
c4cb208b-05d4-4064-b5f6-dc6a8c396419	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device fan: Status Changed	Device fan set to on	f	2025-04-27 10:19:20
0d7d5acf-a09d-4077-9ef8-6a3a10d52967	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.4%. Consider improving ventilation.	f	1970-01-01 08:01:22
97b9aab3-6d76-4113-9543-5cf042738d4c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3180.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:22
b780fa89-7eb8-402d-aaef-b19b5dc0db04	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.4%. Consider improving ventilation.	f	1970-01-01 08:01:28
eb4cb7bd-9647-45ac-a329-de1f5d24a6fd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3183.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
d66bcdd7-3b71-4b4a-b5b9-4de8abdd0139	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.5%. Consider improving ventilation.	f	1970-01-01 08:01:33
45cbd5ad-8cb8-4fe1-b1e4-489eb2423891	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3183.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
69e52df4-6973-45b9-bec2-7bf448dea42f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.4%. Consider improving ventilation.	f	1970-01-01 08:00:01
259cb066-d63c-4117-9235-46bc09f63d15	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3127.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
d8d67665-89e5-4dcc-99fa-3dfd0bc4abc5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.5%. Consider improving ventilation.	f	1970-01-01 08:00:06
7a5cbdae-77e3-4d01-9f3f-76ea88c8d0b9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3174.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
47ceecc9-8349-4f45-a1b8-27809c6da81f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.5%. Consider improving ventilation.	f	1970-01-01 08:00:12
9b5c3dba-04f1-40e7-9e7f-a4ae1ec90fda	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3143.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
cc9a3b9f-d422-4524-8c51-b079eb195cf3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.5%. Consider improving ventilation.	f	1970-01-01 08:00:17
976e2697-fb96-4f1c-8af1-02185d1a8c78	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3135.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
83134e61-7279-499f-af86-034a549610e7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:22
2aa779d8-3557-4c93-a768-3b8e0bf0fb97	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3161.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
e097d0b5-c8d4-4020-88a5-841cdca70873	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:17
298227f2-960a-49fa-b693-7456590dafa2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3205.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
58ffe42a-a0c0-4e0b-987e-e41031652eac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:43
739085ce-6f2f-47b0-8ee7-1e518d985c72	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3300.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:43
983839a5-0894-4125-a195-5e4b1ebb4875	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:48
6059ad48-6235-47e6-ab3a-cecefecaee4e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3295.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:48
6bd15999-922a-47d5-b606-06f5cd7a6a87	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:02
8202d64c-355e-4110-bb0c-6cf10831a013	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3306.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
dc3d68fd-3c5c-4817-b919-ca1089b1cb3b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:07
315e60ab-5e49-458e-bddc-17a5e53a2a1d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3299.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
35cf5689-5371-4985-91e9-3e6783968e34	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:13
05c9ee98-852e-4fee-91c4-5fc087ce8fb5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3296.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:13
35ec0cb2-563f-4ac2-913e-ef57e59eb85a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:18
4163b701-eea3-4dea-bad1-e8c02a134b50	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3302.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:18
1e8a030e-9588-4e25-9a9f-719a2753060f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:23
3eb01ad3-4912-4b0c-9a21-02c1421bbef5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3298.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:23
14eb4e7b-c56c-4547-8b64-58f05f54e3f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:28
45cfcd4e-d001-47be-a290-462a65d0d739	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3295.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:28
c9a15e5b-1347-4b50-8a96-57b45d51d06d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:33
aadcbdb4-bb9a-4178-8b45-2b3d60b0e05c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3306.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:33
fe94b621-86c3-40e6-9a44-53661457b90b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:38
983d9a96-0ed6-4209-818c-3ac0048169d8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3306.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:38
f9dda50c-e8f4-4ef9-a31c-eb63302b94a8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:43
4117bdb9-eac9-43ea-830e-ec0c19b1759c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3309.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:43
ed6d204d-7269-4e57-ae32-a35a7b053d67	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to off	f	2025-04-27 07:44:20
2d83e699-f8c3-4560-b1e7-44fcfc530a07	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.4%. Consider improving ventilation.	f	1970-01-01 08:01:22
a9078af6-bd5b-474f-919c-845fceecf10d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3180.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:22
8f41cc55-4aca-4acb-b477-b94b0a5dae08	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.4%. Consider improving ventilation.	f	1970-01-01 08:01:28
f928e1b7-acf3-4329-bd66-73f9a9a101b1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3183.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
76b53423-5ca9-4cfe-8ff9-9465f176b4f8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.5%. Consider improving ventilation.	f	1970-01-01 08:01:33
8192cd74-e8ca-44b2-b0bd-8646c3408ec4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3183.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
729cb825-38f0-4229-8809-c3bcd0a3bb0a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.4%. Consider improving ventilation.	f	1970-01-01 08:00:01
416b69ff-a22b-43d0-8b91-7035284e14ad	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3127.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
ad0f7641-4d09-4153-9475-1c0984471adc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.5%. Consider improving ventilation.	f	1970-01-01 08:00:06
061bf5ce-de13-44f8-aada-03b76e8fba53	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3174.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
9800fcf6-8e6a-4f70-9138-9aaedca65345	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.5%. Consider improving ventilation.	f	1970-01-01 08:00:12
cc464d41-91c5-40f3-8902-79a355b40c84	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3143.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
b5cc5b3b-80fd-4af5-a840-64c5b05b2583	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.5%. Consider improving ventilation.	f	1970-01-01 08:00:17
cb18096b-a1d0-4173-afaa-7b3f1134a939	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3135.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
e6e1e6ca-f31e-41fc-8a0e-4153ff40dede	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:22
9643a453-e5f8-47ab-9cbd-bb46278302f2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3161.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
996ec4ae-21c4-40d3-aa9e-7d24c6e13b2e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:22
ff630b7d-7e3c-440c-8841-87c870138d50	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3175.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
6b9c25a8-bee0-424f-bf25-259c75569151	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:43
cd5e2da5-da90-434c-b12f-39e4d6d40249	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3300.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:43
01584ef4-44da-41c7-a9f0-31e4104286de	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:01:48
c5a628f1-01b5-4988-8e04-62ed1ecca838	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3295.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:48
75f3931c-dd65-4a62-bd0d-b541020ec0cf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:02
c2f404b2-4f76-4fb6-bdf0-b9904f6f9d77	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3306.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
e72e3706-7b3b-48a6-9b61-1d49955fbe8d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:07
8831a9c3-73ee-4a34-9f85-1c37036ab78a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3299.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
7eb6000c-8d7d-41b9-9f6b-2707e773d675	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:13
dfdcfaaf-ea38-4ffa-816f-e5a9b9b34a0b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3296.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:13
ad308b88-27a4-4e9f-8eb2-60ee8a3bf01d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:18
35d2c0ed-515d-40df-a860-0b7510ff837b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3302.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:18
119cf066-925f-4a4a-bfc8-4873a3235c1e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:23
68a1ad43-a0aa-4a8c-a681-5d9e1955b2f7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3298.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:23
1f23c1df-e600-4221-9a83-4153d21c4c06	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:28
77f9dad5-f915-442c-bf77-71b9e9ac10a4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3295.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:28
86c98aa9-ec8a-4555-bee6-8b8504c65a8f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:33
37ea84bc-3cf5-4dd1-ac2d-316e8728f4fd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3306.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:33
3d66aea6-7fe2-4e70-8c77-6f623bdded78	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:38
ab317bc9-eaf4-47eb-b007-0f7b10cf2bd0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3306.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:38
ac1311d2-ab99-4507-8d28-5eea8c1ff777	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:43
51791482-fa81-4515-91d4-12f0160f456b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3309.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:43
3dc01990-3dc5-4d8c-9ecc-bcda9ddffcb1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to on	f	2025-04-27 07:44:26
1ea7f524-b97c-48eb-b12a-4f0cba212251	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2279.0 lux	f	1970-01-01 08:00:03
b3909373-92ac-4b0a-9053-ede82b583a11	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -95.0%	f	1970-01-01 08:00:03
1b0996c3-239e-482b-9fbb-c7a354772e7c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:08
0a2da49f-4a57-4ec3-9bff-4bc23ae604a6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2278.0 lux	f	1970-01-01 08:00:08
8098ec47-7811-44a5-b7d8-8d4b6bd14897	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: Low water level	Low water level detected: -1685.0%	f	1970-01-01 08:00:08
f2026a9d-13fd-498a-a5d5-bb10f6902fa8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High humidity	High humidity detected: 80.4%	f	1970-01-01 08:00:13
f1bd3cf4-6b63-4ce2-88f9-dab35216d184	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	warning	Cage: High light intensity	High light intensity detected: 2417.0 lux	f	1970-01-01 08:00:13
c765099e-fc54-4aeb-9908-0d87e3b88116	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:27
3c2a8db0-2c6b-485f-9328-055c5c9f007b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3154.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
a5b7a587-8795-4ccc-a3c0-7630e9786363	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:32
b030dcc7-6ef6-4962-85dc-7e852eaf2356	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3178.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
9ff91a80-f2fe-458a-a641-2d8abfe9f6d0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:37
d640628c-050d-4dc8-8184-7e707b0aece3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3169.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
1d6aa186-9fd9-4512-94bb-c359d8f38091	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.6%. Consider improving ventilation.	f	1970-01-01 08:00:22
63e433b5-d87a-4267-bf3f-945e527a580e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3175.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
b6e1da27-ef8f-4a7e-87fd-7cb602deb81d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.2%. Consider improving ventilation.	f	1970-01-01 08:00:48
c9483603-cebb-4565-85ba-6c287977a8f3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3305.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:48
05c433db-030b-4fc6-b35b-f0644cb9270d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:42
f2b303be-4182-4bab-a14b-fa0b00d543b3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3314.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
f4a71f36-e4f1-457a-9980-e07053d031fe	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.1%. Consider improving ventilation.	f	1970-01-01 08:00:01
d5ff73ee-f463-42da-b941-f162381435d2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3329.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
471089e4-6196-49dc-b953-1d6cd3e0cdc3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:01:02
3b5aefe3-b688-4fc7-9984-7477564b6997	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3378.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:02
ebdbbd6e-527c-4607-8e86-404edb8a49be	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3378.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:02
166fa669-be65-4566-9c0c-0927893f8531	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:01:07
10ce79fe-ab15-428a-af41-7ca61551f7d4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3361.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:07
d58789f1-4766-4c3a-98aa-35e26a0b77cd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
ba16b0bc-0dd9-43fe-9d1a-a2f8c0c842bf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3369.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
7fa90e1e-9f33-4262-b219-96c08201d50c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:17
61f529f5-2c7a-4c4e-aa1a-3e9c0801aa2e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3374.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
c446b932-7f27-47c6-bf41-79c81afc66ef	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:37
d8c0e7db-aef7-4108-bba6-503f97d6feca	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3373.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
b96f53ee-c3b7-41c3-9ce7-fe34895f1ac9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
9f97919f-640a-49af-85f2-01a076d6d3a0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3373.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
b9e5eed2-28ca-414f-b913-25b53fbe7ab8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:01
b0c058f7-0c02-41ce-b824-a6d5582760a5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3389.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
b98220ca-4b72-4549-9a8e-c9dc2254ad0a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:06
c9d5cd6b-fef4-418d-bc7b-6871eb1cd8be	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3387.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
c318c167-338a-4b89-8d08-14ce8b0ac8cc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 81.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
eb50d800-12fd-4a47-8bd5-00f0fae38c2f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3377.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
9791beaa-4165-4041-9543-b8c6149c892a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.8%. Consider improving ventilation.	f	1970-01-01 08:00:52
bda0cab5-47e9-404d-8c7f-93704486c0c1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3410.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:52
d3f9848f-c367-447f-b6d4-f5c3c5aa5a1e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:33
c940507f-c72b-4dec-9bf9-72766faad196	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3431.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
623226d3-501e-4c6e-a892-ed76b695f7b8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:38
ce65ede5-ca8a-4eff-9b48-822008ffcb17	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3458.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:38
5f4fb2dd-5421-49b7-8fd9-4c523d926834	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:43
aa2aac84-f8e9-4a0c-be09-b4b4abf03d14	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3437.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:43
52e87184-d38c-47dd-bd24-fcfd377cff86	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:48
0fd2caed-6721-4e0c-aa8e-d6663c6178b6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3441.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:48
2b721ec4-44d9-4fd5-a7f3-7347215f3694	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:53
4941686b-2392-4911-b73a-f04898121e82	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3451.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:53
a3aebb10-3c95-43eb-94a9-5bd6ff803203	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:02:14
ece3fe6a-6df4-47c0-aed1-6e298ee47280	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3440.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:14
be2fea75-9339-4e85-9bec-a7d98a5a1de1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:02:19
e77d129c-6e69-4c82-ad00-53d8e8ca5711	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3445.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:19
022561ce-cab7-4ab0-a6f4-aa53e2f90244	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:02:24
cc32bee5-6820-4d90-9f09-708d43356ed1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3461.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:24
b2d02a30-7783-4485-a169-f207a1f6ef6e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:02:29
c1771b93-0679-4319-9afa-5021cb4ae769	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3468.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:29
c7a9051c-3248-4680-834c-5b362911da5c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:01
30eb5972-69b8-4b09-a5e0-53e13aebeb4f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3455.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
203e8dcf-387b-4ca3-95f4-45aefe5a99fe	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:06
8bad1446-c314-4a63-91a2-59d19fae16fc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3460.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
ae741098-f7c3-4321-8123-a7e4514d7382	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:12
f81e75c9-6a92-46a2-b0fd-5af7a7788520	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3452.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
5625d4e7-be2a-48e2-8ee3-173cc634cfbb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:17
f9a06f8e-b24d-4b73-a32c-c1a625bb9fa1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3455.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
5eb29fc7-5b6c-4d96-8602-2c819e7a51cb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:22
7f5579cb-aa0b-4a4b-bb73-b76f5ee3514e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3454.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
280aaaaa-97da-4ca5-ab3e-1758f4320b01	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:27
c9f9af61-e8bd-4154-aba7-6927fee4c7de	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3459.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
eca41ac9-33e6-4e36-8385-e23a08e3535b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:32
66b2a11d-4bf1-4ebe-9619-df95637a9ad9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3475.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
46261336-1bdb-4137-b312-ae8369626bf8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:37
be3cc7ac-0078-437f-8735-56f101c68855	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3469.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
227b8aa9-40bb-41b2-85d3-7c4cc8145def	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:42
33a1612d-844d-4260-9b64-2c11dde33449	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3455.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
561d88c1-3a8a-4b79-8098-d18079d354d7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:47
e0fe2878-6e77-41be-9e6b-94020355806f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3474.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
2bb53379-0b85-45c0-941a-04f7a8d30ab9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:52
d59e90e8-85e0-41f2-8ce7-e9551904110f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3474.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:52
225ce06e-d13e-43d0-b27f-9642a2d35b10	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device fan: Status Changed	Device fan set to on	f	2025-04-27 10:19:20
fc622ae5-659f-4006-8f2f-9da6532c5eac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3431.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
caf89f90-e60d-483a-8987-8a2ca33d11a0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:38
732be194-cbc8-444d-ab7e-f59eddcc9d94	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3458.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:38
882e9e1c-a088-4197-9ce9-269e8f7d1f51	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:43
1cc41a03-8611-43f2-9d09-e3e742803d7b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3437.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:43
76f68d38-4696-4287-9d5a-f22a78c3a6ac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.7%. Consider improving ventilation.	f	1970-01-01 08:01:48
530fba43-c3fb-42ed-bdbe-0d7f50314cbc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3441.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:48
1dfff54d-8e6f-4007-a256-022e942c69c9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:53
67077a8b-a415-42f9-b8b0-a2e0d087e81f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3451.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:53
c8a2768b-c8b8-415b-9a09-8f26cf04191b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:02:14
740cc146-84e8-429d-a9f0-efe0de4bc021	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3440.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:14
5491608f-5577-428a-ba4b-80bfcbe2320d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:02:19
c71d0828-9da1-418e-89f5-399ac48990b9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3445.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:19
01ab0250-cc66-4c51-9609-4d82d87b3e73	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:02:24
2618f04d-3994-4827-a50f-ac7244bc925f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3461.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:24
bb3f76c0-4e0d-49e7-a0d7-45d8e097c1ff	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:02:29
849b4893-b885-4e52-baaf-291f5a7b9e6b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3468.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:29
79e07b42-b339-47d0-a18e-8b1e3b6685e3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:01
d304e838-a27d-41e0-ba84-42cf5dcd2abc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3455.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
9ac18827-4223-49c4-9c6e-aa892a1fb529	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:06
c4454b1b-df05-4c08-a3ef-0c0e28d09236	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3460.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
806747f4-722c-4340-9cfe-a252ed8568bf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Action turn_on	Device led set to on	f	2025-04-27 07:34:11.129504
ea188e61-0dd1-4713-9207-0e3f656b06e3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:12
94c280c3-5970-4f8f-861c-e491eff5a677	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3452.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
6730ff3c-ba83-445e-ae99-16f6ffacf63b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:17
ca678c9a-d5e1-4160-bb81-985a68d3e1cd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3455.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
11e3ea44-ba66-4967-9a94-867752edde9d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:22
f2b2bc49-e4b6-4ed9-9076-4e250b348bcf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3454.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
91f599e1-faa1-47ca-9eb9-d48e02bb4ea3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:27
47f22475-aec9-485c-90fb-438c4f05d04f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3459.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
43ce087b-1e0c-4438-834d-af255f7f7b67	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:32
50e841cd-d273-4ef3-a83e-0f4084f27570	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3475.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
c3b7ef94-9740-4c46-bd88-863c66b4660d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:37
09522064-9b54-4f8c-a0cd-7d1b8a8af283	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3469.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
6073412a-748b-4cec-a8a3-58d85867a403	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:42
0555f3e4-0ea5-4a3a-bdc4-295a3c8b5c95	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3455.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
613db753-c4a7-45c3-ad19-8d274ea80a53	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:47
e8abda6f-7d5c-4f3a-841d-1b112ee84c6c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3474.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
1c949093-9a22-4635-a9c3-1bb2bed7d90d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:52
0cf75132-b135-4784-a44b-2eb10b1ecc93	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3474.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:52
9dc3d8c2-14a2-4ada-a04f-4deba498d225	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:58
776a81fa-52f3-41b5-904a-063739394170	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:58
3fedbf85-fc28-488a-9c26-08128caec9ba	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3468.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
f7c831d5-1359-4540-aa4d-1bc43a522a55	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:03
adb1cb02-81da-4b75-9b0a-55bbe1478b31	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3469.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
59923664-5191-4fb4-b50a-2041b13fd739	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:08
e22f3b7c-10db-43a3-927a-c49fb8784d7a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3473.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
4ab22e16-bce7-4b5e-8b67-3e69353d77c6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:13
771e1053-1bf8-48c5-8aaa-b5b6d2c1d101	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3463.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
48d554d3-44b1-413e-96a7-dfdde0e017ae	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:18
2b93e84a-0f88-4b3b-9cef-e17cf23b3391	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3472.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
8aac1bf9-cf40-4b83-9998-7e1e07d3a22e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:23
32936144-0c6b-43b5-a65d-8b71a6e5af82	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3471.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
13f2be32-ed69-4519-8417-cb039a559485	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:28
088d54bf-dd91-45a0-9df3-b855baccb062	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3475.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
4ed99c8d-7b5c-46bb-b15a-b010f9ffd74c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:33
38008d12-5ee4-4bfa-a089-986a75d8301a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3451.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
24dfa9d7-11d7-4f2f-8dfa-26bd6c2607c4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:38
ada9a376-c33e-45e1-bd64-7bf26be21d1d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3458.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:38
e4300268-d484-431e-ab90-3592157e175f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3650.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
7fd149f6-7d09-4400-81c3-9cac8972f72a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3634.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
93b0fe16-b82a-4cdc-8cf7-c6fa4601ebfb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3635.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
e0178959-9dae-4749-9749-aec64ae97c20	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3642.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
b8eed25d-13bc-4b8c-b294-d9614a629458	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3649.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
f5295497-0a82-4a03-a67e-715093592669	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3638.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
781ca819-bca2-4f65-8605-2e3964775002	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3629.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
ba58e249-faae-4ce5-a1e7-9fad007fa6b9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3660.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
49887483-3de2-4c49-a3fb-553d0af81143	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device fan: Status Changed	Device fan set to off	f	2025-04-27 07:46:04
799639be-be49-4052-a638-de8d5a9afa23	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3657.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
b6ffc8aa-531b-430d-aa59-4a2b9d2f4d82	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device fan: Status Changed	Device fan set to on	f	2025-04-27 07:46:11
821b5f55-4a52-4b75-860a-044c94b4a52b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3618.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
ee16e9f8-adb2-4fe1-aa57-a628c42b9b44	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
dabcabae-eb7c-405b-86ed-bc08208d52ec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
62de0982-e069-4c0a-a112-33a20c1c1d65	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3629.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
b89a4634-9c44-4b62-ba1a-1d08665edb16	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3622.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
2adca437-4a5f-4eed-bd58-19d8f8068775	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3633.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
24665633-fbe9-4510-94d5-7a8585d75b62	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
3aed641b-4768-4ece-84c6-4d1895ed9c72	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3648.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
16dc76b9-fc7b-4019-b17c-7d6deade5f17	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3642.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
8aee8cde-6885-4607-8aed-e2730ce33be4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3677.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:52
90d40c52-5b8a-4ab5-a74f-9f78595dd071	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3620.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
d67ae0a6-5151-41ab-abca-78dabd81dc3d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3468.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
6dbb96f2-050a-4472-90e2-9b278b53b5d9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:03
1c7c4b89-565c-4837-a378-0694f730c14d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3469.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
dd426364-f4f9-4a03-a4f6-c4305a0eecd6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:08
4247166b-35ee-48b0-be6b-285910c0fcfa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3473.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
6fc2dbf5-d7e5-41a2-a874-2471750696f8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:13
36ea11c8-3389-47ac-b0bf-7ad565a0bd85	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3463.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
0a1df0ec-60ef-416f-8587-1994ec746423	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:18
52110c7c-063a-4a60-85e7-978b2b7d77e6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3472.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
c96e5e9e-0485-4c16-8c06-83d0d7b1fc97	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:23
5c75cebd-5074-4857-831e-6e89f7b035f7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3471.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
aa963e14-75fa-49b6-8e28-c34598be0103	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:28
83c287d3-ea30-47f5-8f1d-c7dc7470a7f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3475.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
a8ec9d26-0012-432e-a6b7-d3a6034fc79c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:33
b77a8ec3-87c3-44a9-a837-93b9c2341f64	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3451.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
853a2e9d-b073-4f49-830e-fb8e02a8ae7f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:38
2d5a79b3-5d9f-4b12-9d19-04dc9f55e6f2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3458.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:38
d30ced69-c66b-4206-abb8-434a3079137c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:59
5bd59220-66fb-4f86-acd1-5b5ba6840a9a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:59
b6ab34cf-1a77-447b-ac3c-c368ab3a8a0c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3475.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:59
99436dac-5ea8-49c7-bc0e-7b3ef3125c37	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3475.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:59
45377e66-2546-4546-b053-c5786b807491	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:02:04
05f26c24-2360-4875-a016-b4d1af40037a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:02:04
ca5217cd-5999-438c-a2e6-e9fac93d0cde	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3473.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:04
c7f31115-da95-4d0a-823b-70ea109075f3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3473.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:04
87bf90ad-0783-4ca8-a426-f6e1959430c3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:01
6fed80e3-4160-4993-8d53-118e23937081	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:01
1248bc57-a6ce-482b-b29c-67a022a15077	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3491.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
3aae8393-a77d-47d1-a8b3-36b6d2441ba1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3491.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
43d56f09-6a67-4a3c-a08d-b16baf2c0c98	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:06
d2c758c0-7278-4366-bca8-30e1760fb858	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:06
f33e47e7-318e-4ea3-856e-c15954cc1991	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3463.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
8435a679-3ba8-490b-ba1b-856a708d026a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3463.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
b8649475-0818-4a3c-8801-30a7bd4a9f51	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:12
c49dbb51-a296-4a4e-98d1-e8eeaf629755	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:12
5225b58b-fe55-4d43-b082-14ee1fe3751b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3443.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
0a445d0b-fe69-4ab8-8c1d-9c597e23093b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3443.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
ecc4fe11-36ed-4459-bb86-c05fdf91b460	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:17
2a3d9a8c-6b27-45f5-bc2a-066978d158b1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:17
eac9da2e-8a24-4a48-a927-35d7aedd512a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3472.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
1854ce26-dd71-4077-865f-670b33d1fd55	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device fan: Action turn_off	Device fan set to off	f	2025-04-27 10:19:26.383858
896e522e-964f-4a5f-b37b-f4100aa0683b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3472.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
7db31089-7ada-4619-a376-f47768942e19	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:22
8a477768-f96c-4eb0-96a6-05ac0431bddd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3477.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
4d803bc2-1084-43f1-a279-a50fecedbcdd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:27
84d2fadc-b270-42f8-8549-37940e0c5389	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3491.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
aa430d19-eaba-46a7-b141-e2abec76d6ca	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:32
a8932148-4705-4189-9eff-cde9ed959c7e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3485.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
bdd9dc2d-6b76-47e0-98d2-d4f8bf568abc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:37
5e0d712a-b815-44ea-82fb-0ae0e1f69940	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3499.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
d763e215-b0d7-443c-9fb0-dcfe64088f1e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:57
81186526-399a-44df-b12e-c084ab9e9e2f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3489.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:57
6bbd23de-2414-4e3c-8724-9f36e48bf75e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:02
ec6af616-95c7-40d9-8ca5-0d7c189acc06	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3505.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:02
1d6e5100-aeca-458e-8e91-c5e6e6615934	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:07
a1febf0d-f5cf-444f-b223-6f17e83b5a32	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3498.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:07
d541ebe4-ae5d-42e3-9f82-8d034c3d30c9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:01
2e40146c-457b-4494-91ed-b20dad9fd4d7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3503.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
17472022-8cd6-48aa-a232-b8d6a7783da3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:06
a5fdfeb5-2e7c-4867-a5f9-e0a0d4123d3a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3493.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
2bbe89eb-8848-443f-9671-e0fd6b0ddc17	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:12
b7b9735f-7e92-4527-ac3d-9242b89c4110	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3519.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
4cb84702-3bda-447a-bfc7-9be380699124	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:17
62efd48e-23d3-40ed-90b4-631b2aa7d16f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3511.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
3baef7cc-165f-45b5-a204-6ce23c1c287c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:22
da3fb159-de7f-4030-9849-40f409f488b6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3522.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
97cf7df1-5f41-4ea3-bf9b-b1cb01bfa03d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:27
fd784a91-c1d5-4f19-8071-e825fc5e7b07	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3506.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
b702a07d-ec76-41b5-89e7-a61d789661c4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:32
8a51af7d-b37a-4b9e-a3f6-88444f8e7c5d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3527.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
09574a89-c6b3-4379-97e1-2b672aeb5710	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:37
24034b8c-8567-4614-99d0-bb4a9ac3e0e0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3511.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
2f2f1572-e8b2-4985-9285-c55be235fd8b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:42
9c4e60b0-8a4d-4268-b195-baee5726134c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3510.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
7376b718-6ae8-4cf1-9d50-e4e3b840ecc3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:47
69a8ede5-8a3d-4df8-a354-4a8a11f87ea6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3520.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
ec09f61d-b424-4353-832d-04a60df53e42	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:53
2c2d283f-acff-481b-ba37-1c6cc1597aba	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3506.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
9a2f2118-8b28-46a8-8e68-74c9dc599615	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:13
bd9ed3da-906a-427f-a3c8-85ec771bece0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3539.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
8281fb2c-7267-4af4-aa1a-e07232341669	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:18
9102fde8-971f-4888-9625-1e99dbab38e2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device fan: Status Changed	Device fan set to off	f	2025-04-27 10:19:26
54fdef94-2b47-435b-b52d-ccd76a30d89f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:22
424d7c40-cc89-4ee6-9e94-bff53964d643	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3477.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
3f6beaac-2956-4e53-96a3-c0ae7958a1c9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:27
352bab29-8452-463d-a924-eccede398d1a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3491.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
d2936e66-8783-4a7b-bf13-dd1c1c483236	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:32
c1d5791d-8bdd-4774-b6a9-8b34af0e1128	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3485.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
f28f3665-c6de-403f-9b96-21da87a42ae9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:37
22b06f3a-d088-4c81-9456-94a047193301	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3499.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
a3591891-42f9-4375-aa00-2bb188d8a215	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:57
69bf58df-21af-48ea-bff3-9d1b8eb1d7f7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3489.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:57
c8605f6d-ed5d-41f0-a236-e3e66e48e03c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:02
66c2bdd2-5320-4c30-9bb8-b8e2387825d8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3505.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:02
5a1f1f86-b8d9-4e52-8dfc-835de73cc6d0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:07
7f62beb2-24d6-4781-b005-74a2dd61cba4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3498.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:07
5e03a460-ef5c-4322-98ac-f8020868810d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:01
dcb01f20-b861-490e-b9f9-ded5849478b5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3503.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
794d791f-74f4-400c-8241-80959088d6d7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:06
cb7364c9-f0be-418b-9909-68fbd54d3d39	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3493.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
f88c0053-2408-4e8c-bc37-c06e2a1e1257	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:12
eecbfe9d-2543-498c-9fd7-53d812aee2d1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3519.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
f8533e18-cb10-4018-bbf2-5cc05f1e9976	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:17
8ab699e7-c186-412f-af96-c02daf40561d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3511.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
47bdbd76-8200-4289-bb9f-91526d3137fb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:22
bdeda4cb-9343-4d2b-8334-af2c10469b14	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3522.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
10d8c7eb-c35f-4784-815f-62d8d0876aa0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:27
615bae4d-f775-419d-a116-8b7d93946cc9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3506.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
ee2e1ba5-2013-4a58-b601-cc8856f5ee8e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:32
dfb9902d-784a-4e04-ba7c-a9ec11984d27	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3527.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
b1c9d8dd-bce6-43b5-85ca-13beb7631b1e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:37
4d17442e-0789-442e-a276-a8cc0e2edfb3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3511.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
77778d9b-cf7c-4dc5-8318-38a6c2ad22d6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:42
01eed1cc-41ff-4119-86b0-6cef1b1ce426	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3510.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
28dec3ab-c250-4f2c-b07f-1d96ade69f20	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:47
4cb8ee34-270a-4999-9342-33733c0cf0f7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3520.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
3728df34-1107-4f71-bf11-f64a762ac9ff	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:00:53
f58de4eb-426c-4a52-9693-bc742e914002	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3506.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
cbe0c8e7-9eb3-4c19-bbfb-44e4d7a94f0c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:13
a9be1ef1-41c6-4376-8aa7-92639159a9c9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3539.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
b0401458-8e6a-43d5-8c7c-e905e7462dac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:18
efdb4e9c-5cf4-4324-9035-34ac1b58383c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3534.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
64011198-c246-42c7-9a27-7acfd398c8e5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device fan: Status Changed	Device fan set to off	f	2025-04-27 10:19:26
50729f56-9cf4-4a39-9e77-bc581fc6e3bd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3534.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
2a398fa2-6afb-4ffe-99bd-9fd73d60f136	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:23
a3f40de4-c992-4236-bda0-057874812d5a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3525.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
db951add-ea98-4e05-a161-f4b01eb7e10c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:28
cfefb04d-a6b9-425c-9cc3-71f9b0143f09	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3538.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
8181e21d-8445-4f82-9b09-057e1b097789	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:33
0a2e988b-9a42-48f4-a0ef-7a31226fd1d0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3540.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
1125d9aa-7b89-4acd-837c-9f00eb9f3043	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:53
b5a3d346-fb57-4f1e-a1cc-8413b11a9a58	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3550.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:53
baa89185-d876-4c05-b093-51a0152589cf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:58
d2cd903c-54b7-4a55-8710-6d023dadc979	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3551.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:58
ac7eb376-9425-43ee-9100-08d9c5c9ebe2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:02:03
d89177a7-d840-4367-8393-df4be8b00b37	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3602.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:03
17e561b0-0d40-43be-8f4c-acbe4884608d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:02
228dbbb6-5f8e-42f9-b53e-a1a7745b644d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3556.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
b1e5212d-cdc3-47f1-905c-8cb8ae23bce3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:07
c182e14f-b178-4101-9946-5df36f6071bb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3557.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
84669193-a884-470b-b00f-a99465a67534	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:12
241261b6-da45-4524-a254-aef9cbf89243	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3559.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
380917aa-5403-4cc4-a926-26b09c65656f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:17
3738ae04-2408-45b8-b559-46bda2ec1c8a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3577.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
14e7b241-87c8-471e-8f17-a047ff99600f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.4%. Consider improving ventilation.	f	1970-01-01 08:00:22
d56c4818-d46a-4d2c-853a-efdb528e2d45	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
a7e3d5d2-1a28-49e9-992d-944ffed3b6ed	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.4%. Consider improving ventilation.	f	1970-01-01 08:00:27
60ea811a-acb9-4871-a303-d4c91bacffa9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
594e4851-95e2-44dc-aba8-1b22689707c3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.4%. Consider improving ventilation.	f	1970-01-01 08:00:32
b87bae0c-dbe5-4d5d-99e0-da6ab10514de	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3577.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
547b3775-51b9-4b9a-a6ab-5b7ba29eafdb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.3%. Consider improving ventilation.	f	1970-01-01 08:00:38
2c88e6e9-dc80-4653-af83-b156ae0578e1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3595.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:38
e01b275f-1313-46a8-9a80-0e3b23af6b47	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.4%. Consider improving ventilation.	f	1970-01-01 08:00:43
edb779de-38e7-40e7-9bb3-46f1113dd5c4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3570.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:43
649e7ec1-66f6-4dd4-949d-bb22e9f9e466	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.4%. Consider improving ventilation.	f	1970-01-01 08:00:48
3af48dc3-251c-4f17-ba5b-ba95b82d8bf5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:48
8d0bd92a-8903-45c8-a901-f534f0858667	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.3%. Consider improving ventilation.	f	1970-01-01 08:00:53
45d0cad8-be61-4283-a85f-8c2fc1eac270	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3563.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
1493dff1-b5de-490c-b8e1-6457e74030a8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.3%. Consider improving ventilation.	f	1970-01-01 08:00:58
7bcbb9f2-6fdd-44ae-ae2f-ba8aded2b010	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
893eff44-ae23-4641-8ec2-2e1d4bf613f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.3%. Consider improving ventilation.	f	1970-01-01 08:00:01
c7fe8f18-fabd-4f2e-b5c0-18b26d3e0a73	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3567.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
43f8d9ff-bfcb-4d05-bb90-deac2ae8963c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.3%. Consider improving ventilation.	f	1970-01-01 08:00:06
41c8ed11-6ad7-4930-bbe5-d2781c519e55	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Action turn_off	Device led set to off	f	2025-04-27 10:20:55.357349
1efb35bb-f4d3-498e-8bb2-1f9bd13c327a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:23
a50c7a6d-46b7-48ba-8096-772013262dae	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3525.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
4c8b518c-00da-413b-94d7-afe1f4d3c15a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:28
38d3dbdb-23fd-4bc4-9de1-ad4bd798a436	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3538.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
ed782e0c-e376-4cbb-886c-289df68ddd27	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.6%. Consider improving ventilation.	f	1970-01-01 08:01:33
efa2cba5-e253-4672-b7b8-8b6c336645e2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3540.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
b1a45b92-1535-46e5-be41-4c0b176505b1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:53
a9c5027f-3a85-4802-8b33-01e4106d4fdd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3550.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:53
1b1b5d54-090e-44de-aa68-933304c79f4f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:01:58
305632a4-f376-493b-94f1-b6e0c721de0e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3551.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:58
a78342df-9d38-4d64-8df3-3e6ccda0c3b8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:02:03
97ea7dd4-4d7f-4fac-b02f-de32d55df339	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3602.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:03
e5acfb73-03b9-4805-a48f-e2ba14c6c73b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:02
79e379b7-d6fc-48bf-9455-8bc6ec815377	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3556.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
f9510472-2327-4070-b920-18513e35edb1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:07
dd090fc4-933e-4aed-ba0a-70d2fb6dd369	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3557.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
044d7149-595e-46d8-a2be-17cfd1f36244	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:12
65f38875-fe58-4d7e-b34a-8521d542ee48	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3559.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
ef62bb01-e019-4206-9f87-558db12769e1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.5%. Consider improving ventilation.	f	1970-01-01 08:00:17
cba83688-c2b6-4f99-9ca3-311f43048796	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3577.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
4683015f-ca54-400c-baab-b0290c75c476	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.4%. Consider improving ventilation.	f	1970-01-01 08:00:22
a48d48ae-09a0-4e2d-9a19-9f04c4e00855	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
789fa53a-d65c-40c4-8f20-e7795b5e7eb3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.4%. Consider improving ventilation.	f	1970-01-01 08:00:27
3e555d8d-aa43-42a5-8a9c-f5851253d087	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
81a7564e-6d8a-48f8-8f5e-9a8b1d5c05ab	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.4%. Consider improving ventilation.	f	1970-01-01 08:00:32
cc0f1960-0888-4afe-8980-35fe1abcbf5f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3577.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
138aa2d4-7ac2-4a28-9b11-68307bc5d407	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.3%. Consider improving ventilation.	f	1970-01-01 08:00:38
89c7fc63-566e-486b-b242-b56309b3764c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3595.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:38
1df80d2b-d828-422b-b734-a256fe33359b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.4%. Consider improving ventilation.	f	1970-01-01 08:00:43
b666f5a3-86e1-4f2a-9950-ce77a0c42212	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3570.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:43
07d1070b-5a01-408d-b16a-d49ccc2b7c40	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.4%. Consider improving ventilation.	f	1970-01-01 08:00:48
8a91cd9c-6a03-42e1-97ce-0414d9d734ec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:48
4e129ff8-a74c-4531-8e5f-635d3054bc7f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.3%. Consider improving ventilation.	f	1970-01-01 08:00:53
2e8c7303-b7aa-4ba3-a860-1ef52322ed13	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3563.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
315064a3-4ce1-49a7-915c-7e51604746ec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.3%. Consider improving ventilation.	f	1970-01-01 08:00:58
07baa202-765e-491c-94c9-dc0c190f1b4a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
a7d1f7d9-abf5-45d4-b2cc-b2fe11f11f72	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.3%. Consider improving ventilation.	f	1970-01-01 08:00:01
f6efd2bd-0c21-44bb-a531-7198185e825f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3567.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
045d52c2-f701-4e66-af51-adcffe7e391d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.3%. Consider improving ventilation.	f	1970-01-01 08:00:06
f5bb8bfd-a21e-4aae-926a-47408cedc062	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3562.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
bf261aa8-4fb2-4fb9-a6f6-79e1d8f4d74f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to off	f	2025-04-27 10:20:55
b302f2e5-1ef7-403b-aef3-5217f72f3490	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3562.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
73865fe6-9dc5-408e-ab85-0ffd02031df3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:12
0efa85a2-4d5f-4dc8-a47f-de31b1dc83d4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3597.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
c083fe74-8ff1-43eb-9169-6dd62b461c6d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.3%. Consider improving ventilation.	f	1970-01-01 08:00:17
d1fdc650-2aad-4ca6-aa6d-aa2bddb90d28	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3568.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
5f509c0d-e5a5-4a75-bbaa-17c9b237cb56	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:22
b0ea5943-b675-4189-bda9-498b4794feb6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3561.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
707720be-8e2f-422e-823d-dea68bce81fa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3650.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
f3b59bf7-c3fa-430a-ae3a-e829ccea5837	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3634.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
308cabb7-6c76-4ea2-9a8d-59ae3127694f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3635.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
7b61a159-3e5a-497b-babf-970b1d449aff	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3642.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
324be205-e7cf-412e-b0d1-657679e161fe	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3649.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
07eacc2b-e2fb-41b8-b645-90577b559d45	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3638.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
f12b56af-1894-4147-ba0d-72cbcd6bd77f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3629.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
538668f9-8364-43a1-b864-bcc7fc0d02da	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3660.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
9f64903a-aceb-41b1-bdb1-9fe757f2f73c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device fan: Action turn_off	Device fan set to off	f	2025-04-27 07:46:04.686267
93d547ab-555b-4de1-b9ee-c5814d78109e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3657.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
2d739e8a-92e2-4b2d-a215-57fd44d21412	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device fan: Action turn_on	Device fan set to on	f	2025-04-27 07:46:11.480077
be1ce614-d9a2-48d3-9e40-ae9b62ee1639	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3618.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
0eb4315e-80dc-4d3c-8d14-1fd366e872b7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
76690992-d52e-4873-88e1-c0feceec7be2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
15e4c611-630c-47de-8c62-9c06fa78affb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3629.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
ed9be7a4-bebb-4b64-9a4c-8ec6666b7268	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3622.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
2668dda0-f9a8-4a2e-be50-fdc3d46ca66a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3633.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
c2637ba4-8fd3-428a-b876-87357857d3dc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
df79826f-b4fc-4b58-849e-1615d467ea05	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3648.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
6f85e62d-a978-4df5-b771-ae9a05fb22f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3642.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
bbe71d78-ec6d-47bc-96bf-8618ee0cb4c6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3677.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:52
d5915ab5-46b5-463e-836f-0d63046339ab	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3620.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
a0293e33-c38b-414a-b952-7d538061d259	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3483.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
72e53b4c-2c6d-4275-aaf9-e85de5e784df	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3518.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
98ebc789-b88a-4242-b772-871007807739	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device pump: Status Changed	Device pump set to on	f	2025-04-27 07:47:33
ff98fe88-f5eb-4b17-9c95-98e2fc24f4f1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3517.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
b9b1ea84-6f3a-4091-80ee-55afe625eb73	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device: Pump Stopped	Pump turned off after 2-second refill	f	2025-04-27 07:47:35.396484
7510bda2-d6fb-4c95-9931-526a74afdeb0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3641.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
db17b45d-f55f-4662-a727-1e11e7e93c86	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device pump: Status Changed	Device pump set to on	f	2025-04-27 07:47:43
fa0a6d0b-8c4e-4853-bd98-84881e8d9a9c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3488.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:38
240e2750-20ec-449b-aa93-6f42b63c01cc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3646.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:43
d52700ac-515e-403a-bcd2-09ab1fb041a0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3603.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:48
03f7f81f-a174-48ca-92ad-af04f24bbf03	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:53
36f84628-7889-4348-a8c1-f4d827d75ea0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:12
524f9bca-b3d3-4165-8ede-0051b516d477	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3597.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
517f4be8-6923-46c7-9b6d-a7354c139347	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.3%. Consider improving ventilation.	f	1970-01-01 08:00:17
ca883175-1a8c-4002-8d27-f9d2562da562	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3568.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
61345a34-bee0-4cd4-9491-a5bce0398f16	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:22
4b260b01-3495-4771-91ff-8f04ff7c086f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3561.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
8c9ca633-01f0-4e60-9b12-f80746b50842	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:27
22515671-b390-4dbc-9b29-8e8d8ec6a3ac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:27
45a9870c-d585-454e-aba0-1e4aabaac68e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3566.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
3fe0b1dc-4fe5-4b22-9004-cf3fcf6fa58d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3566.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
d1f55ac6-dac6-4f83-94c7-31c9d83cdc9e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:32
4f948b8a-c63c-4ee4-8470-59352ec29850	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:32
8356375e-9214-40fd-9c7d-4fce4ce462a7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3579.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
276b6aeb-3554-4ef2-a4c3-ffe45b057ea9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3579.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
5bf1f85a-344c-41c6-8e84-4e47a0f323f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:01
e3ca4d92-ff89-4397-9774-bba8a85e683d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:01
9b9ec427-0c3f-4d71-9132-2ec16ce8402d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
76b04f6b-3990-4b48-a274-943ad7637a08	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
d770ca91-294b-41bc-b752-298120bd4cbb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:06
6f66ac51-c558-498e-9081-0ec54dcfadb1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:06
edc18343-a51b-4390-bfef-ea3f6111f358	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3573.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
aeda8195-cbc3-42bf-9b57-176467d6750b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3573.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
52f94019-66b6-4aa8-87a3-846f33cd367b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:12
bc019d22-66b3-4b6f-8e67-c396acd221a9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:12
bfcd0fa3-057c-4e34-9c8f-979c4d10f8c3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3600.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
9d07b51a-8c8e-4a18-8975-16a5b2e9bcd0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3600.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
2d85e45e-60eb-45eb-b9c1-e47eb501d6d9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:17
e289fe55-9874-4fe3-ad14-97fe52674b52	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:17
853ca25f-7db4-461d-b43b-f6ab793c6ada	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
f27e84ea-ecfc-485e-91a1-cb19e2357609	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
0d98b2cd-9f74-4ec6-80e6-b8496c391c81	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:22
3d41fde8-924e-404f-b81b-8679ed21d881	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:22
adf847fc-5f63-470c-acde-297234de6170	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3554.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
29297b58-29f1-4877-b06f-a807dc97fe23	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3554.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
9fbdf22b-fd9f-4b8b-951b-f6573eae52a5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:27
2a851bb5-ac5b-44e4-a468-d793a52fe889	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.2%. Consider improving ventilation.	f	1970-01-01 08:00:27
dd939ec4-4d93-4f71-850b-af69aa7ebfa7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3545.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
1cb11421-47e2-464b-a16c-8dd9b0b8b7d9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3545.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
d20ae477-4741-4010-a608-b6a243f5379f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:32
3e8dcc05-739b-4fce-9e46-f4dab0e9273e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:32
30984a03-76ee-4d3b-bde4-3cefe2033578	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device fan: Status Changed	Device fan set to off	f	2025-04-27 07:46:04
bf613c43-bffe-4c74-a268-44ab7080a222	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3523.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
ad9cbd39-0be9-48a6-8a6a-03154af538a5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:37
56328ce2-a782-40a1-9def-fe15229b6a2b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3524.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
0991219a-a70e-4e44-9524-f026e8f0f16f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:42
fc43fcb7-14f2-4cde-9e8f-bef4920ec08f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3548.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
22f60b02-218b-449c-a7f8-fcb81e4ae8f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:47
e2b42f13-525f-47ff-a495-03a7431e1ba7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3545.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
2c98e059-d463-4c1f-80f0-082d259dc077	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:52
6d9ccbc3-1298-4f90-939d-d395bfa8d0e4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3537.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:52
b7706db8-4a78-4a88-a34f-21407ee7e5f1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:01
dbca45f8-3dfa-435c-b288-00b0874c2920	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3563.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
7641db75-3796-4dd2-a427-86b50116661d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:00:06
061fe2a7-a4d6-4de5-9c05-236be1aac9ba	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3557.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
b5b7940f-44fe-4e8c-be9f-4a92d1145d8b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
2e06fca9-ca2d-4361-bd47-31809d8b3da1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3569.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
130bcb60-df5b-41ac-a7a2-d2dba3f74324	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:00:17
f15c0338-674a-4775-a190-0ee4ca58fa36	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3579.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
67277dcd-24a2-4b85-b0d4-b472e2ce1828	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
2490df95-9a09-4204-8ab4-732e22e420fc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3573.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
bdc6eafa-28ad-4461-bf18-6345023cd850	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:00:27
e0309ba6-5855-473b-a3a7-4bf479e81c4e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3568.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
70bf90b4-d68a-4c47-b08a-2a4dc844120e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:00:32
31d9aa4e-2a27-4c04-b690-99e263686801	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3571.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
cb68de32-2bcc-470f-b17d-2fb63bee9fbe	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:37
79dcdd23-6840-45d8-9cac-83ba802bec9c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
05e5aa08-9a90-40ef-9752-b0699786f0eb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:42
50533672-9c41-4ae7-8a87-4d5a6c71563a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
d56d3a7b-e9a9-4a38-9555-796e980c93bc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:47
f9cb8bf0-0dc1-40a6-851c-eb04655cb339	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
89e2bcfd-3802-49eb-a532-44eb1107236e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:53
5e058fe7-4f22-464d-86a2-3830e8a82e20	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3613.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
887c9ab1-d352-4663-bc1d-9ae1d7bc5518	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:58
012e2473-d5a0-4360-bd42-3a5ab5c59460	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3600.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
6f37ee8b-d80f-4840-9189-c751b062bb1c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:01:03
8217460e-a8f7-4510-9faf-56e4084db69d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
41ec384c-a7c7-4d5c-8b82-af59610f6995	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:01:08
1d8c0e57-1a88-48fd-8b50-8e65f0fc27d3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3604.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
d006a395-5c15-4c97-8111-43f9842f1e7c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:01:13
40b3decd-9fcb-4eef-9567-7d265041c315	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
1e7c4d05-d24e-479f-908b-0b45726e81ef	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:01:18
d80ec7ed-094a-4b38-895e-75568e555754	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device fan: Status Changed	Device fan set to on	f	2025-04-27 07:46:11
44b0d602-bfdb-4593-9c29-ac99b0466951	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3523.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
21b7e3b6-c579-48d7-ae8b-9910050a4c9d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:37
0ce603f4-a989-48c4-8e52-ba174a31ca2e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3524.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
a80091a9-f151-4f7a-87ed-cf53df20231f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:42
8c4195f2-a8a7-478e-aaae-5e1beefe471b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3548.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
8bff4656-aa92-4fd7-8336-25adfd7d6ecd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:47
34ac30dd-0724-4b82-95c7-bd8b68ed23cf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3545.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
e7ab0543-961d-4e2c-b6f1-9a1720b69d10	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:52
1088dae4-da26-41f9-9131-10cf7cb9af4c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3537.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:52
3dbdd99b-2b91-439a-b3ba-5a67f10c0a97	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:01
5d2ede37-fe86-41c6-bfdd-f1f975bd345f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3563.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
332dbdb3-69db-4b1a-8586-f54eaa4a7b74	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:00:06
60b433b2-63d0-48ba-9c44-305845eddd3d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3557.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
6068ce3c-36a5-4488-a4ab-b33301aaca92	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:00:12
a5b37ca3-ecfb-4617-a321-cf8a5fefb614	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3569.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
43ac3d91-a880-453a-a8ce-a83422d06eb2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:00:17
f6359c36-5bd3-483d-ae6b-4610abc31531	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3579.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
c451dda7-b54f-4853-8bcf-16f8a972973c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:00:22
4c878869-5021-425d-8c7c-5f0792f4eff6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3573.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
1eee3e13-4216-4a2b-b222-d9861932c20e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:00:27
78cc5eda-7544-4714-82ef-30f28370bc1f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3568.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
7ff0c581-cd98-40ce-9dc9-3069aff3c00a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:00:32
5a1d0577-d589-4c2b-a1cf-8c8472097aa7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3571.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
f4726f29-c0fd-4400-91c3-3b617fd9e433	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:37
bbdcbafa-f0a7-44ae-b078-8b01a967efc9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
c5c3cfe3-5052-424c-84ff-577dfb328d0a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:42
85b2c996-f84a-4780-91c8-ef5f1ccc9742	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
8e6cad4b-8031-46e8-9687-91e2094cc714	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:47
67c6b91a-8bc3-448d-a13b-3edac31244a5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
5ff862ee-9b6b-4e97-a9d6-671df701ae00	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:53
d76973df-e47d-4a38-8026-cbb6f2d018f8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3613.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
a382e921-d2ed-499d-831c-efff2278d2dc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:00:58
8e8a75b7-f4f1-418d-b151-0ab0da7f7feb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3600.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
666bd23e-b45a-42e0-a29f-0a10a00717e1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:01:03
518635a2-4e1e-407b-9e3b-6222d3ddf9e3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
7ab451a8-f0e6-44e9-87ea-2cbba0a1bd2e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:01:08
e9faf1c6-9968-40f7-baf6-742eaf21b47b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3604.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
b50945a7-4ede-4ffb-b8db-feae099d5616	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:01:13
0f13ba18-2813-4c0a-9fc2-ef7e5b699dd0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
3e2961c3-5409-4c27-b0d2-1687533faa0d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:01:18
3298ce8d-f139-4622-b582-a38b2a17a2d0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to off	f	2025-04-27 10:20:55
b5987841-d2fb-47e5-ab56-3ad5dea425b7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3615.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
01f994ba-b878-46d7-81a1-cf768f0be82f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3483.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
e2bd8e31-ed1e-477a-b359-6e72189a28ee	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3518.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
81488c78-fbc8-478c-91a5-a7e87f7cf329	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Action refill	Device pump set to on	f	2025-04-27 07:47:33.392794
e85123b5-c678-47fd-86bb-ded9f1396a1f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3517.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
cde7fdce-4195-4fca-9ee7-a7ad43c3344b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3641.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
8b719e5e-79c1-4e6a-88b1-726a01b581e7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device pump: Action refill	Device pump set to on	f	2025-04-27 07:47:43.028606
eb7880ac-afb8-4a69-8fba-a3e8deefc349	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3488.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:38
a300ecf3-7b04-41b4-9ac4-c2569df47e0e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device: Pump Stopped	Pump turned off after 2-second refill	f	2025-04-27 07:47:45.031722
3f3791d7-e853-4aec-8195-0f648ff71ff9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3646.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:43
1523ac62-68b6-47ef-b966-17db3e5a0129	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3603.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:48
9b994d46-03a8-4679-834f-966a88a6e3b4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:53
467dee4d-f26e-4d0f-8ab7-6844d744f888	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to off	f	2025-04-27 07:48:03
d9128b90-9fd0-480a-94c8-92c5c5d98115	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3627.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:59
256f15ec-ffb1-416b-a26f-27c4e18bee9f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3627.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:59
cbed2ff0-dc5f-4ecb-acd9-f927b7d287dc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3639.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:04
e7cd41e3-126b-40fb-9e97-79084fe09dfe	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3639.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:04
be2c97b4-ee0f-4f0c-b7a0-d368f3d35fd2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Action turn_on	Device led set to on	f	2025-04-27 07:48:12.911018
5eb2a3c2-7891-4f43-bdf0-bd79bb3669b6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to on	f	2025-04-27 07:48:12
b9a3b3de-cccf-46ed-92dc-23795ffba573	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3616.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:09
5a9ed85c-ca2e-452c-90bb-1d65d137312e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3616.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:09
14288681-b391-4770-b06f-e2fcfcee93af	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3627.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:14
63e1db2c-ed20-4407-81bd-4763ee17a5ed	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3627.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:14
c3332920-ac2a-4dc0-936b-d21b75e79feb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3626.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:19
14714e7e-a52e-4108-aa1d-5de00a03a153	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3626.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:19
dba4f676-7e4c-472c-9b4d-6e91046ffefd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3631.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:24
3ea1828e-47cf-4fc5-9ee3-6a065aab99d1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3631.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:24
6ab91eeb-91fa-4b79-9d12-7a1415390b57	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3630.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:29
a92ed3be-6b3c-4a79-9af9-2015d45ac6ca	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3630.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:29
243de561-1459-456b-a15e-47c02707e99a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3641.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:34
a689e93e-7a8a-4d58-bd27-60dea716a455	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3641.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:34
806389b8-e0a3-4067-99e7-4632c2e8357e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3641.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:39
d4e91933-827b-46bb-a490-e400c2c2890f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3641.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:39
3517a0e8-70cf-43ac-bf21-ea093f562c94	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:45
74c8c276-6949-45d7-abe9-094884b54012	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:45
8ec06fbd-b8e5-41b0-9b23-4d00872837c9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3637.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:50
bcda838a-5572-4374-b058-5078cf671faf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3637.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:50
94ee1c51-72a5-4bca-b7ac-3ba51ddd9d32	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3639.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:55
ca39f3ba-b5a4-41a5-9e01-6cb531ced564	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3639.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:55
4a20f288-adac-4a92-8ee8-a85bafc95276	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3617.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:00
9a19be1b-c727-49a6-8c49-39b533c9045d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3615.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
ca5b7ab8-3761-46df-a771-58f19ee4414f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:01:23
06dd0d0f-e864-4605-97db-cafddacdf587	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:01:23
63f74d42-2eeb-43af-8aaf-d45bce0b76f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3606.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
19b4d051-1723-4d91-a6f4-2191aeed00de	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3606.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
ca6ca25e-bce7-4aa9-ad73-c492f9e53f8a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:01:28
398dfb25-102f-4da4-a154-7ff84252db47	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:01:28
1dd312c6-8daf-43ae-ac39-582849434ed1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3600.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
642814f4-153b-4374-bf88-d2851b554848	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3600.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
a9584577-aede-4b60-9526-fbcea68aee08	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:01:39
a11ceaa7-5095-4a88-b87a-2eb743d61c52	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:01:39
66597463-74ba-4b59-bc81-3c6f56322cde	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3612.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:39
9b4df225-cf12-4cc7-a772-14ca466406f5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3612.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:39
aa01e3f2-51d5-4aae-8d0a-76cf3995eade	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3618.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:44
0b000286-47e2-41c6-9c07-539de682bd78	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3618.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:44
c73aed49-b5b8-471d-9064-570b70f15f6e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:01:54
3bcc5174-8082-4d47-9bb0-4002807d0d03	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:01:54
7b796079-f354-4feb-8387-6199f306fd11	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3626.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:54
3f14bed4-190a-472d-a5d1-7b6482ed26b8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3626.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:54
9384d266-df5a-427c-a6df-4a91f3d4249b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:01:59
fffc1756-d40b-4d04-ac2b-a637f517f70f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:01:59
3fd58cd5-a8e3-47d1-bda4-8f7cfa8c57dc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:59
8f776bc0-2035-4c26-8f33-38351e7f884d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:59
b8958528-7e11-4863-b43f-56948b2e41be	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:04
55ee6e1a-780d-4c17-b6f5-bb8cee5d3b3d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:04
b69baffa-301b-4ed7-a7e8-c2cb1ee4ba22	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3615.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:04
ece124e6-58ae-4d2f-9f94-7736888d33fa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3615.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:04
7e554000-ff3f-469b-a08e-de561963b93a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:09
e7f5a25b-fe1e-447a-a5a6-f3a3cc6993e9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:09
6d9809a2-c5be-4944-88b9-aa2a53c33459	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3622.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:09
6c843158-fcfd-4c69-bd18-f8059ab883b2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3622.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:09
059f9185-c83b-4974-ab5a-e7731ef85443	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:14
dab351e5-4c78-42b6-a40c-0a87d6332709	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:14
9a92fe72-b6e9-4311-98ff-656cbfe34bcc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3616.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:14
9e652476-2e5c-48b9-8615-84bbe9a4c9fd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3616.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:14
1f86ec48-d52a-4c36-ba7a-c981906fe973	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:20
a630bd40-ee6e-40bb-b3f2-037b718afb63	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:20
76f475ac-e222-434d-a05c-2c2c1c029b5b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3629.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:20
672355f7-35de-4fcd-81b2-b6bab93aaff9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3629.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:20
22b11dc7-ff66-4eca-abbe-28ab844784a4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:02:25
b9cf4b23-7918-4cd9-a71c-9b0fa890b3e3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:02:25
adedb93b-4fab-4331-827a-de416c66410e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3636.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:25
af1d6de9-6d2c-4efb-8d72-8cceba474218	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Action turn_off	Device led set to off	f	2025-04-27 07:44:20.659531
be979d05-b0cb-49f7-8b06-fe419a0b0612	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:30
cad64058-2459-40f6-bb65-1525fe5c54e5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3627.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:30
19768996-c96b-4f9f-9ad9-ba0d6414de46	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:35
2b773613-d915-48f5-8d2f-7b3973ab957f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3607.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:35
ff30dfd1-50e1-4ed3-b53a-02b90195189d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Action turn_on	Device led set to on	f	2025-04-27 07:44:26.465489
a67c00cf-961c-43c6-a08c-357670908f14	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:02:40
55afccab-d3d5-46b1-a9fe-b33e23383e19	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3626.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:40
1b648660-7a7a-4e48-90a7-8bf6f06cd7da	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:45
b21fdb03-3c2d-456d-9360-a5daf0e06b5f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3631.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:45
03590cf2-5962-4fb3-8375-8b8428fc1dbe	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:02:50
a20a7399-d0ca-4153-bd13-dbd999a571f1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3627.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:50
20eb8355-f372-4c01-961a-4a0391729a14	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3634.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:55
905b30d2-b8cd-4581-836f-378d2b1cc500	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device pump: Status Changed	Device pump set to on	f	2025-04-27 07:47:33
3de40af2-b5a0-4f51-9d90-c582f6ad7136	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to on	f	2025-04-27 07:48:12
46962a76-fc12-437e-9cca-cabec2347360	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3635.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:05
b6005e73-ec98-48c8-ba9c-168608410970	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3625.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:10
ee001e86-56fe-4f2b-80ad-84fbf84cadff	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3627.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:15
648de45e-190a-4366-8356-15c3b0488a91	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3629.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:20
d5560da1-4077-4720-8b3e-6b44fea2519b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3642.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
f262f562-920e-4d50-8a19-2b77d04bb6c1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3664.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
690f067c-4b0d-4569-b40e-e36afa2c35e1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3659.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
a92520e4-13a1-4958-b07c-f2524b3404bd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3667.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
e4ac4402-2d06-4013-88ef-b63df5316052	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3675.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
cd02234a-826d-4c00-ab89-f502e59445bd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to off	f	2025-04-27 07:49:53
726a6f28-9ac7-4040-a37f-c55030263f7b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3666.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
8cc23cca-09bb-4f3b-8f02-3a0659aafee7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3665.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
0503f5fd-a9f5-4b6f-b87b-49413c8d9245	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3687.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
2cb841ac-837f-4a2e-a8cd-13bf249eece2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3664.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
116f6340-bc99-46ae-bc3b-c0fb2a6ed811	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3653.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
3fccb162-ed67-4567-b2b4-024e9773da4f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3657.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
0b7f57d6-4a89-43c8-b11e-4fdcf41e714f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3678.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
41c12ec6-c936-4dbf-8fc3-79b2d829f598	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3678.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
b2b02c48-ec64-4e2a-a8da-56610f82e851	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3694.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
f926ad3e-da9d-48fc-adaa-c471cdacf98f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3713.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
028ecddf-9994-4c8c-9ebc-7f076d5d23e4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3721.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
81ceba06-b2e5-4ee7-8cf6-80a197c57948	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3694.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:38
7686221a-e659-4093-b3af-d6438a0344d5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3696.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:43
7343a686-00f8-4010-a737-b0b3f9312b17	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3636.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:25
34953340-e42d-499c-96f2-686a17bc10aa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to off	f	2025-04-27 07:44:20
ca2de385-b6c8-48d4-be65-f93dda654376	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:30
7463f89e-d1a5-4345-8d1e-2fb012fb24ff	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3627.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:30
a80c799d-8d5e-489e-b50a-d77a2eb8511f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:35
10064b1e-0116-42e7-b1c2-6e05a501b6e0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3607.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:35
66b6ab91-6c2e-4f9c-99d7-1591333d8fe1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to on	f	2025-04-27 07:44:26
6de13717-aad2-441f-8694-1873021a63bc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:02:40
49dd5642-42e3-47cc-bca4-a4c6d85f2b39	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3626.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:40
d8eb93da-0682-4feb-9fbf-b63e2a359e3e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.1%. Consider improving ventilation.	f	1970-01-01 08:02:45
fb4ebed1-11f1-4dba-99e3-3df3d4de5290	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3631.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:45
93d35e09-562f-49d6-a288-918ac4512939	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Humidity Alert	High humidity detected: 80.0%. Consider improving ventilation.	f	1970-01-01 08:02:50
73511167-451a-4d38-8692-8ecc550edeee	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3627.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:50
0a09e5c5-e46d-4b2c-97ea-cdbd1475fffb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3634.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:55
e0747055-1492-4377-ae32-3088dc194f3d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device pump: Status Changed	Device pump set to on	f	2025-04-27 07:47:43
b6ca01e0-7e1b-4105-83e4-e28cf485972b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3617.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:00
317256db-54db-4976-b920-946b2806ae49	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3635.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:05
aacfb686-1207-4539-ab09-c2b6abc9f50e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3625.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:10
53caf6a9-7f4f-412f-9aea-2850c829046e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3627.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:15
163e215d-5477-42ec-b0ca-389f961d7d31	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3629.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:20
62cd5cc2-6532-42b3-b875-929f4b848637	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3642.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
43f3f354-7867-4bea-904e-8095c263143a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3664.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
1d1417f7-71df-4dc6-aa64-e1ef37f53071	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3659.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
1b322dfc-5ddf-42c0-9c51-f38ffd93df4c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3667.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
2b4af9b6-062c-4e34-bc8a-309bbd5cc240	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3675.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
42f3bb73-9b41-4a2d-92bf-01b4e91a22cc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Action turn_off	Device led set to off	f	2025-04-27 07:49:53.04208
9788ffdf-8e21-4c35-a5fd-a9281dadadde	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to off	f	2025-04-27 07:49:53
d92b69b8-9765-4cf3-954d-ebf5da29867f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3666.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
d364808d-165c-43ae-933d-a6d11c54695a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3665.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
6a207e4c-a5fc-4511-88de-4a57881a32af	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3687.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
b644c483-309a-4551-a272-0a2b90a36212	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3664.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
4a2fd594-68de-416c-940e-ebfef246ccdf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3653.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
4818dde5-302e-4aa7-93f3-bdf642c9de7d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3657.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
3b8eb1a0-9e2c-408a-b627-9b62d9cc00f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3678.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
c0fe9678-bcad-4342-b988-0c9a939193f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3678.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
65fa6a26-ff40-4ef8-8284-048d04a41df0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3694.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
173ffe03-fa7b-41e1-9daf-a59d978edb4b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3713.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
2f3e0117-c602-4eee-b6cd-77ba7c2b98fb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3721.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
6701b20d-27e1-4011-ad65-bfd147a3c782	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3694.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:38
4b15e451-8899-45ac-94ef-3a81c4f8ec08	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3696.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:43
3737c54a-b126-44c7-a8a3-2ed5beb9270d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3673.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:48
e0803971-30ab-42f0-b12b-2b40925ca844	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3312.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:54
78579305-bfe8-4f46-9260-cdafa246e9dd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3614.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:59
647ede1a-0d5e-4ca3-ac21-e0dd5dd8c076	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3695.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:04
d49a39d0-75d4-4484-b52c-617bd4468cdd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3646.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:09
60d1daa6-a392-4f97-bf04-288072b0db79	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3684.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:14
189aa902-a054-4a69-bc73-1c1daa0277c5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3696.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:19
18e53abe-0488-46e5-b133-60fba4b4617e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3683.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:24
53abb56b-38bc-4192-b801-c789d4479229	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3687.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:29
b4819ac0-50ef-4365-aa6e-afa740855a47	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3554.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:34
cf46e74e-fb29-49a2-ac76-4a99de7376f0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3470.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:40
cb772147-d46e-4174-88c4-c287e231ad6b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3603.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:45
1c4d471c-5e0c-47ff-a198-6ae0f3238343	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3615.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:50
f4cd59a0-a1f5-4ca4-af68-fe23597558ec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3673.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:48
3fffe90f-65ad-4215-b02e-ccb80c97cfae	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3312.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:54
7eb2f532-aea3-4a7f-ade1-f5426ecffc03	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3614.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:59
d8af5f7f-d36c-4b06-9f6e-20aada9922e3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3695.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:04
235a35a0-77b2-4baf-8092-65fc73457bf6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3646.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:09
60d03911-6e05-4151-a2f6-17c133a96380	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3684.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:14
c4c6d840-b35c-4fe7-9166-2b24760f0868	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3696.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:19
d9182f9b-40bc-4705-bf8f-8ec9cbc9a0de	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3683.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:24
2bf4f0d1-418a-427d-856d-049bdb6ff7b7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3687.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:29
d93563d1-c38b-4467-8ae9-e23bed4061f7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3554.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:34
981fec2c-44f6-4c36-9c4d-5c8614f39848	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3470.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:40
b7e0c95f-3d3f-45eb-811f-3aea5c9283c2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3603.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:45
4c0b6a02-0ff0-4c64-a847-764c1cca0f55	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3615.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:50
18ec074c-508a-41ed-ab50-0831fe464746	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3427.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:55
17383bdd-8206-4b14-8afe-bdd17c0a4d1b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3427.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:55
4c99966f-0595-4aad-a324-350e9e61bcf2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3553.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:00
c83b227b-f24d-4771-8aaa-bd022d120480	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3553.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:00
224e0838-13fa-4bee-a6f0-945a068108f3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 2924.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:05
4bd2a0ec-6e76-476a-b4c9-b1887a024b7c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 2924.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:05
51573129-cd0a-4752-b517-792131200a9a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3062.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:10
58b8863b-5f68-4a10-90a3-85c8aa688075	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3062.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:10
b3d75811-b090-4605-847d-e6e0bac69127	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3350.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:15
5b126bdf-51eb-4edf-aa1f-805b520c9468	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3350.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:15
6c83f47c-47b6-424a-86f1-53de0cb2f9b5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3344.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:21
84a8835d-0621-4fb7-b928-7b40c5202f13	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3344.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:21
1afb903c-2fbe-4b4b-a7ff-1cf7b52db663	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3691.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:26
0ee36f7a-c417-4e81-8239-5cb308abb671	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3691.0 lux. Consider reducing light exposure.	f	1970-01-01 08:03:26
46f79b5e-4d6b-467c-b60a-6dab1897043c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3697.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
442d61c6-97f0-4290-b189-4e152ec31406	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3697.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
be046568-5e31-42de-829e-95c3310f004b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3706.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
21fdb22b-70ad-4239-94c7-7eaa4780714c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3706.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
abf3831e-6ce0-4e6f-9ad8-8a9cde372db9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3709.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
fdaff693-f35d-496f-b796-60fcfe326a5f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3709.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
0111232e-b0af-4944-86a7-591fbfe3f6ec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3690.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
f223f0e1-9ffb-481a-a3d7-03ab3dd9778d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3690.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
f82f8dc9-7020-4867-b5f5-9e321efbe690	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3691.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
8d849ef5-f726-41c5-a85f-ee6b9a163efb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3691.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
38298004-b540-4e60-9dcc-77cf628a85f4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3717.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
267e49e6-0133-4e94-bb92-be577a2f7a47	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3717.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
c8e8fa8f-9719-4172-88f6-0b686dcae51d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3697.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
4dfeec53-64bc-475b-a4e5-9aad39df552f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3699.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
c9957118-0b17-470b-99f9-4b5ff436bf25	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3696.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
be342bbc-5258-41e2-a9a0-83d3e93681c0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3707.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
ab0d8ea5-e53b-484b-a0cc-6d744d3a91e5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3697.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
470d7d9a-1d29-4051-aa6d-aa4c69e54e67	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3711.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
8ee7eee5-1577-4724-afa5-814f77351ae9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3723.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
904479b2-3063-4b3a-8f9a-3deb0b0818fd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3717.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
2e93e16f-11a5-4589-be9b-40de5a500ce2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3713.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
7a3a921c-7a82-4a83-bb20-703af04e739f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3730.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
29770277-171e-45bd-bb23-970d9142b490	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3711.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
93fbbe5c-f8ee-4c3b-bc22-2bda1a63cb16	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3702.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
46ec51e1-3c23-42f3-acaf-ee57ada7db8d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3703.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
c89fb74d-f2ea-4715-af77-fc08aa9b2238	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3659.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
73b92496-bbbb-4db4-a788-3702e088c176	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3369.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
232fc9ba-0f18-4a9f-bdc8-f94e3f832ebe	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3457.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
4ed29390-7f29-4b88-905f-a5a00ef7dd34	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3697.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
6d358359-b53e-4c37-894d-af8b3f17a3c0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3699.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
b9a47430-ca65-45f4-80a9-e459fd13d811	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3696.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
65b3a100-5a32-4b06-a875-df70cc8a3ce4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3707.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
439871ca-526b-444e-831e-c0bad5a80d5f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3697.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
916c7089-581f-4139-8236-e21ee78fd56e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3711.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
00230a00-7f99-44e0-8f2c-7ad821cf7c6f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3723.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
c993715c-e171-43a7-9940-9ab81204349e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3717.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
86a453c4-5486-4cb4-b09b-e794c6dd9ae3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3713.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
3a4e5f96-fd1e-4646-99ca-c9575ed6c0ac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3730.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
12716536-d7dd-4203-894e-711f0cd357d9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3711.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
1434cd1d-dd79-4633-9df2-3fbf97f4bcdd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3702.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
a42754d9-235a-4fc6-a2cc-b3953b0a6f38	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3703.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
550d4d5d-fd1f-4fdb-a7e0-5be0239a36e5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3659.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
ce26deab-c6e9-402c-b9e8-b1777c2c8f37	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3369.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
2b454b0d-35fa-4c9a-97e0-607a3805a650	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3457.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
c96a0871-e25d-44ab-83be-6bb6a777205f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3635.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
5e622c95-0332-438f-ac72-e2d8b7ab7a96	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3635.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
5394d8fc-9ebe-484f-bf67-c6daceadfa25	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3647.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
44e8eeba-9ae9-4ee5-b8c7-146441bcca68	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3647.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
7cfc5495-b275-4492-8830-5744b5ea7bdc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3653.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
2cf4e2e3-f933-472a-8bf5-370c238f9e7d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3653.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
a6008e43-cfa1-4185-b26e-cf8cddc1daad	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3681.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
00093c14-84b2-4676-8400-154da71324e6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3681.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
4ebed5ef-204a-4da7-a1d4-1758a9e24504	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3648.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
b4bece48-3fad-4c4c-84a9-1341b10e28be	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3648.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
27187401-d9c8-4f34-b3ac-a960d6addaae	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3655.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
8a8848f8-b770-4870-8695-7abee8881646	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3655.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
932f35b5-ec70-4f7d-9e73-f98ece44c27d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3649.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
0b44c46f-cbdb-4488-b34b-fcd5c974787b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3649.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
4a90d8f5-533d-480f-98c3-3f5c392b458e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3709.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
e839c8b7-ae25-4404-b397-c3f53bc616cb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3709.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
e4dabf58-f445-49c6-a33f-82e3acccd1fb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3733.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:33
24c8a9ed-f022-4287-a1d0-fabd04de3eba	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3733.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:33
0f8c6598-e796-4b69-a13e-3c6f26752bbe	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3728.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:38
6a424d27-33c7-4e52-9ddd-72e2d3519818	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3728.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:38
3a11b272-3e6d-457c-b753-2c9e4145ef7f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3729.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:43
1586ca7e-5aa3-4c23-8339-96d0b56e2f53	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3729.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:43
ac32be2f-433f-4e72-a427-675369e8e50b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3728.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:48
b9cf9cf8-b1ec-40dd-a8c1-688234e9df9d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3726.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
905e21ca-6227-46ef-93d5-2427f348beb1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3569.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
cfb0593e-19d7-4f82-a654-57aa3ddf536f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
5a7ef09d-f399-4355-9eb9-aa16c21296f6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3728.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
60144ca5-1ccd-4d09-89d6-1fa46fe08633	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3733.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
9ba04ac4-a78e-43a3-a945-d7e01444f199	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3634.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:19
f6e2d6b9-203e-46ec-9877-333d85188e1f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3575.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
5c12bf48-1944-4e3d-82ba-7eadfae3a496	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3616.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
21fb0bc4-52fe-405c-a871-8a6d9886bf5d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
99d05700-892d-4787-89b2-91b063d73dec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3664.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
f590f40a-e8e0-4992-81cb-70c9a299107d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3667.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
89a79c86-d264-4d70-93e5-9b6a7131bb9d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3536.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
c851cfa0-4f7d-4cf2-8799-b43e07c0803e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3523.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
a9a78241-1d86-447e-9651-88ba9d25d66f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3152.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
da2431bc-b162-477f-91e8-40a406ff14c5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3673.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
7d00fd82-1d9a-4708-bedb-65bbae71f21e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3661.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
9f9b4b76-a4e6-41f7-963b-712a8b65de9b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3305.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
ea56c43f-6dce-471d-8191-5228b1d8939c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3646.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
e6b29847-a3a7-4ec9-90c0-433419854464	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3152.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
f18b0cc8-de9d-4e13-b828-ddf5f403de2c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3031.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
09a41466-91de-48d5-b4d3-b5644cdc637a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3491.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
c9f680e8-d19f-4023-aa2a-72e0f7557b4e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 2971.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
18ff061e-8fd6-4045-a1b0-904b8c1aca62	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3615.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
787469e6-30b0-4363-bca3-ddbef346f1a5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
f7291fb9-d9f6-44f1-b419-137fadd9eca4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3629.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:34
fa6685e1-ff84-4324-bd42-332992d0447c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3599.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:39
ff196838-783c-4eba-968c-12d74bc654cb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3623.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:44
89e3ba00-bba1-41ee-b8bd-1150cebe31c0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3626.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:49
02ea44c3-9d5e-4241-8640-8fba51e162d4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3571.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:54
f4883e0a-b624-47e8-a423-d449aeb54a87	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3574.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:59
b1887f36-86ec-4ec4-8dea-5521ee071592	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3533.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:04
7eec8877-4c81-4ccf-a389-31aa76c0dbf4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:09
69517fc3-ec7a-476d-b110-549bbe298f77	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3498.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:14
b889269f-edba-46bd-aa4e-c175ca9f23fa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3697.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:20
64a76daa-41f4-4776-924f-cd614c18081c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3697.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
95f9e1a4-4455-4235-b32e-e39883c1b0a4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3728.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:48
84881f9b-05a8-4baf-940e-99fe9636940c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3726.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
a885ee4a-dd78-4a0c-929b-41062ad1e0a5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3569.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
c91569b3-3257-44b0-91cc-0e26b59be1cb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3632.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
9f06643f-888d-4683-8e0a-44d8935e4324	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3728.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
ffc9b486-48c6-49db-8551-f71852dd8630	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3733.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
05b3af47-1c32-414d-a8b0-90e0259186b4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3634.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:19
31899b3c-475d-4764-9355-b337038de610	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3575.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
78f61c7f-9099-4ff7-94e1-907f3e242851	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3616.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
f1a28f3c-4c9e-4fe1-9fad-543d1bebec98	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
fe173fe5-7603-48ac-b94e-1932491ca743	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3664.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
05cc6ace-2f67-4acf-b813-95cceaada8aa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3667.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
921c61c9-5ec7-4483-a836-759e43cee75e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3536.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
8ddd2556-5406-401d-b9c3-ee28fd9a02bf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3523.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
37e031ae-b61e-4563-96b7-ac3234b47a5b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3152.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
c2f145e9-59cd-41cc-b855-a94849c22402	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3673.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
8584d236-561d-4bb7-806f-2fe74aceacf1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3661.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
4711a0f5-7c2c-42c5-9662-867f26052ab2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3305.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
be8cfe73-ff4f-4d73-bc2b-387f4d4615aa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3646.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
800057fc-2af5-46a1-82ae-02f246a50cb4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3152.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
df6d5212-cc5d-4cbd-a56e-1bd919643000	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3031.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
ad76d113-073c-4974-b894-fa5b0e5a109e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3491.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
fa8e9a4a-a0c2-49bc-afaa-12d8ae016902	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 2971.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
2929190c-ea6b-42b7-ab97-ebdd5ee44712	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3615.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
050880dd-6995-456e-8bca-92fc673ee6f4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:28
98b20b44-c5d8-4fd5-b305-2bcaf9c08818	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3629.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:34
71ee3f7a-803c-4475-b7ae-5b158450fa46	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3599.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:39
56085f27-406e-459b-b73a-9e5977c6f66e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3623.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:44
96f76884-0b2b-4348-8558-37c5022764be	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3626.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:49
12b926a0-c3c5-47be-9f41-12f6aa6cfeef	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3571.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:54
00911956-636e-4c09-b886-43d2adc6a203	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3574.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:59
8752d2b2-e644-4293-b4bf-2b4a616ce637	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3533.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:04
82aeea02-bb56-471b-a8d2-ec9942f80c65	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3583.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:09
0ccdb740-a706-4fbc-b24a-252e9216ea56	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3498.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:14
0c13942b-07d6-409d-9fc2-5751cf1e8fcf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3697.0 lux. Consider reducing light exposure.	f	1970-01-01 08:02:20
d1d4681f-fb47-44fd-b258-50ed262ca175	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3697.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
51269546-73c2-4bc0-b0bf-dc0592460010	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3797.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
43b940dd-0f4b-4d57-be41-1c467195dbb2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3797.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
832ae669-2641-4deb-a1f9-2f25014b92f6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3780.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
29d8b6fb-2e13-41ec-ad69-fc90e4f3b132	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3786.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
c8f1fc96-4b87-442f-a2b2-a8ea8ea34475	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3781.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
e324da91-f017-4508-8215-4ee9635ada97	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3685.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
8d3d091e-1284-4ebb-aa8e-fdf6eeb7e747	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3543.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
3a0f3c7d-f339-4879-814b-9a5c085d5eb9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3735.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
618e6fe7-f3ce-4fea-b52a-5d1e3278b15e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3754.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
36b48115-00e6-4019-bdac-1d43604e94b1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3728.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
d35474f8-5f2e-425b-b24f-c9d19ebffae2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3739.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
c1e87337-c685-4a18-a41f-beab8cd2434a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3747.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
3f191d16-6335-4f43-b82b-a33a1a023032	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3740.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
58142a35-eeef-4c8d-bc8e-6fbe2d38ec34	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3755.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
cd68261e-a3cd-47cb-8742-4e37e64fd04a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3743.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
f5a03175-fc1c-41fb-9b40-a09ec48cc7ec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3738.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
f397d6b8-b43c-48e5-8fd5-e76bd16a1dfe	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3759.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
0b616ff1-b95a-4181-bf91-4cb10f878dbc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3728.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
ce29c6e4-f667-4f40-8292-4ed3b08f5f8c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3738.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
bc1fe7e4-f339-4a4f-92c4-86116527ac79	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3735.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
f320c2be-51ae-4864-be8e-ff5926b24b1b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3735.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
1339c8c2-1df2-4f23-88ae-cea7660463d1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3743.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
312bda06-056f-4c7e-97bf-1f4f67b34573	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3747.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
2db4bd6c-a1cd-4e96-990e-dc8ca30f9c1b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3738.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
f99be582-5e5c-451a-94f2-31a7cc7058f0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3746.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
baf42cfe-8747-423c-9d20-33d5d9b1f730	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3749.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
a57e1de0-3147-4625-9a2c-37464c9baf18	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3742.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
dde9613d-3bb8-47f5-b149-ad231b8ef31c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3760.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
d5d07068-a700-4590-b88e-5b34963b2e84	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3734.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
0b6d2b9c-5478-47fd-a271-9886af7de020	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3729.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
7fc38286-acc1-4689-8824-674dd98f643a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3749.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
ca7eb7b9-c8f8-4adb-a30b-56c62c16fd53	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3742.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
a765f85d-ef10-4295-ab1f-a274f4253eb1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3742.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
066f5e3b-96ae-48a3-b678-3d6ec5965ebe	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3733.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
a905d7e8-09be-474d-bf9f-ef186b812c36	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3727.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
af514609-f513-4612-a2d5-a2145ef8bf7a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3729.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
ffb9c7a4-a0b3-47e6-8f7b-57d0e881af1d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3703.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
0389cb20-c653-4c13-ba60-9615c2dc604c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3705.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
fd156a63-34fa-4c67-a426-365697e4d2a4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3715.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
00130df6-4da1-47d0-8a5e-4cd30dc8d66e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3703.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
367fc9de-092a-433d-a5a3-91f15417408b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3780.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
57e17f3d-1613-47a1-8426-50b0efab52cb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3786.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
6f2f8e0b-d136-409f-98f3-29443aa964f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3781.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
0b131f56-eaa3-40a0-8842-3a22a360719b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3685.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
12618cfb-faee-4552-a21f-3a919cb2dc6e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3543.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
f329dba1-7c79-4809-912d-dcb185e3549b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3735.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
3f7d4f07-11fa-4444-90d9-026df6cb6b36	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3754.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
7beb0120-92c4-4a95-8512-db58121b31f6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3728.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
bc27d9f9-767c-4be4-8c7f-9faa2de958f5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3739.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
0a501322-876c-479b-8f8a-3d4c7debc8bd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3747.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
18afc345-63bd-4adb-adfd-6bd325a9cae0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3740.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
1d0ba976-d95a-41c9-a12d-8b03106b7c71	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3755.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
bdf0b414-949f-437c-af0c-4837259fcf30	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3743.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
50b79aa9-dc82-4447-af62-3588194d0661	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3738.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
a05fea22-cb7e-40b3-af92-85a0dab8b88e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3759.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
b7a6e7b7-5456-46f0-a88a-9a5ccfa66231	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3728.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
a2a64e31-dacf-4be0-9ae6-df07ea8cfbad	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3738.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
efa227fe-5296-4b95-9032-fbf6d0fab17f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3735.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
9d9a2a25-430f-4da0-8f77-9f435b4dccaa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3735.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
979122cd-799d-4cbb-ac5a-91ce42917f37	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3743.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
fef6d43d-cc74-4de2-8d4f-a837e6b1bf9e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3747.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
b54916dc-4ad5-4b20-b14b-8bb56667af0b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3738.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
022cb0ad-8314-4786-a10d-de9c83d2c5d2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3746.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
cc89e416-88fd-4765-9547-81a5be4a253f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3749.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
ddf2b8ca-7033-4b8f-933d-8a37f9dad46f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3742.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
2e90878b-cdb0-4a85-8a3d-e43f0487c0f7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3760.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
a80a720e-4a86-4007-9438-5231ce5d2d22	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3734.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
94e0a859-a123-47c4-9577-b23690a4136c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3729.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
4e91fcd1-d268-409e-866c-29b7bee1b954	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3749.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
4e506aab-7acf-4bc5-9f31-18da4e70e7c9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3742.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
1b50d648-1bbe-4575-999b-30935d85ba76	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3742.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
56fabf52-55a9-4171-8b43-902e81a4648b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3733.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
f1471161-664b-4218-9026-188b2c600c33	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3727.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
6e33ce19-e4b0-4e10-afd9-90bb3aa60158	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3729.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
0914abdd-52f4-4305-962f-7b3b04d8f791	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3703.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
848cd978-f60a-4ed7-8ad6-646922a15586	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3705.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
6b1d67ff-1947-4b9d-9ce3-4cd7471b2f54	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3715.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
6ad88e17-3305-406d-a91b-f6622eb87f07	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3703.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
6ed6329d-c1d9-4aee-abc5-226553729898	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3721.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
6b302d4b-9a2d-46f7-962f-6f1adf42e176	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3721.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
e2690673-46a4-40c2-9c6f-1c6678e85e2c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3730.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
197ad6f7-0add-4757-92f4-9b356a435ea4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3726.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
2466a63f-9036-4160-9978-71545722382b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3721.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
e002c69c-4a04-4a2a-965c-1d6b81a79360	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3721.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
2a647cfd-e9da-42cb-bdcc-14633ad21bb2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3730.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
0e833287-9888-4916-8957-e63dd9d4e918	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3726.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
a67663f6-5a1e-4e60-b575-dacab1dc48bf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3725.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
cdb0b395-eca6-4988-945a-3dc1987f7fa4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3725.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
da551cab-c34a-451f-b8df-c1e3201a71e6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3775.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
02136bc0-f38e-4efb-9e88-73005fad00a5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3775.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
6a11d8ac-5f47-44f0-aef1-ffb9afbb45c4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3803.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
f62b5450-54e7-41ac-9e72-68c0f6025aa2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3803.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
93974c52-60db-466d-920e-7697b36e5dfd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3786.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
48364d30-f402-42a5-8f9b-58f1bcf3f365	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3786.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
91c2590f-7bb8-4b60-8b6d-7ae3f0491c95	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3787.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
8c3b77f7-6fc7-445b-af74-ad43354e6a40	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3787.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
616c39fd-1d96-4616-ac57-0aa647a72f2b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3807.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
1fafea86-4240-4a41-9648-ff2c78928143	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3807.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
1fdd2804-5e5c-44ce-97ed-6eb073602a0f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3792.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
cbdc4388-136c-4333-b78b-f82ae2f39f7b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3792.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
b72b9bc9-84e3-4536-81eb-3a2f81a693af	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3793.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
22c55827-6682-449b-84d2-d9fdb3271da9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3793.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
7ae0afc6-3763-42b5-8e1d-5e1e7451027e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3773.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
1368d59b-74fa-4e78-a2b0-10c23a3b949a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3773.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
5af615ed-fd96-4137-b000-34dbd0e8edf9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3761.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
a8c2f890-00fa-46d4-a40d-b32eb459f5ad	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3761.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
ce93831a-5787-4a1d-943f-ef2caaf5b046	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3765.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:38
0b416d11-84e4-4cb8-a38a-47ba558a93cf	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3765.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:38
27218233-7842-4352-8d49-9da392b6b513	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3771.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:43
9c7d63ea-e116-40c8-905e-e3f3edc63017	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3771.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:43
9229ed02-9c60-4668-b4b3-d648ba43b646	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3766.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:48
5f014cfd-4625-432f-b3e2-63e38bb7a54f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3766.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:48
dadebabf-653d-4d82-adae-b7e2c196dca9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3772.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
7d119f8e-cb41-4a88-85f3-df042ce35596	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3772.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
d67ddb1d-b74c-4f47-aca6-3002d73ede82	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3757.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
73f4eba2-c047-4967-af5f-e37bf44205a2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3757.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
bcaf0ebb-ddd0-4068-8d5e-f99284ae6e26	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 7.0 cm	f	1970-01-01 08:00:58
d7313bd8-fec3-4012-a2a6-a165af3646de	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 7.0 cm	f	1970-01-01 08:00:58
e64b93d3-0c38-47a8-8239-feffb2f7ffe7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3811.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
08f3cd38-f915-4856-983d-24f06bfcd194	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3811.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
5db7207b-a1a4-4426-8af3-7d1b02bcd860	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	info	Device led: Action turn_on	Device led set to on	f	2025-04-27 10:18:50.118555
e2bbde66-5df2-4187-bc92-bee92d536dc2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3809.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
f8fed2c7-42dc-45fa-8677-39300d103478	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3771.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
b34d8a86-ca0a-47ea-b485-d0acb47137da	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3761.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
0fc498c6-38d6-46c7-b472-8c5b5decc19f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3754.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:39
7d32e4cb-e893-4736-bed3-7b8587d1fd03	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 8.0 cm	f	1970-01-01 08:01:39
1746241e-a0d4-48e5-8492-54cd46ef7fec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3744.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:44
37886e86-7814-42cb-a040-fc2b5e8db390	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3751.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
e0f41836-324f-4b32-a63d-b7ad2a2187e5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3760.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
6d7c7605-2e37-42a7-b03e-e604ea3b6696	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3749.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
411a0ddd-d93d-42e7-ad81-514d7f8003a2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 11.0 cm	f	1970-01-01 08:00:12
9b2f0e55-9dea-4392-898c-313938fa509e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3703.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
89ea2b10-7d97-4029-81be-34b6abc62a76	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3789.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
e24505d4-02c5-418f-b8ed-bcc22fef2fba	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3770.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
c171d811-e8f8-46ed-87d7-1bfcce2d7dd6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3777.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
00be13e1-316c-4c2f-8f90-b662f91112ae	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 55.0 cm	f	1970-01-01 08:00:32
fd0e4a40-bc32-44f2-a8c1-09abececda38	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3809.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
e942c4dc-619b-4417-9185-3a0c8b3b2116	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3771.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
fabfbd8c-7d64-49f2-b4ea-bf4ac833e09b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3761.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
7043423a-ce7b-46af-ac9d-df682df71064	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3754.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:39
0552d9ee-09d8-437b-aba7-13c0f3477eb5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 8.0 cm	f	1970-01-01 08:01:39
ffc1f498-1655-42d1-b070-01600cf159db	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3744.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:44
ec87f3ba-91e5-4d93-9866-d8bdc263944e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3751.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
19722eb6-ad54-4db2-9f81-84d13cebe574	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3760.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
7f1ba74d-0069-4e5a-909e-e0c8dfe24792	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3749.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
0e204041-f6d9-435c-888a-8589ad32035b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 11.0 cm	f	1970-01-01 08:00:12
f7e955be-3173-4893-a541-6f6a4ad63adc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3703.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
bc68b7f8-e8fa-410a-89e7-19bb14e917f3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3789.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
d3754517-e6af-47a0-98ed-cbb45c577c75	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3770.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
5ce9747a-a1fe-4785-9d35-066fcd963ef7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3777.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
63221f6f-6e17-4aa2-8901-24923a484fe3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 55.0 cm	f	1970-01-01 08:00:32
620c5350-de7f-457e-8c27-aa9146f9c126	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3773.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
2bcfcbac-0312-4fc4-ac39-4f9f7d9f8335	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3773.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
dc03317f-cca8-4c9f-bcb9-c8c406c959d5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:37
323cd05e-70c0-45b5-88f9-68a1407e22d9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:37
07be4ea8-2c1c-4cd9-84ff-3a9966d00d9e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3767.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:57
900bbedf-fc62-4901-aa89-fc085af4db3d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3767.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:57
55b1c5ef-9bb4-47c8-a9bc-79b1f9d9e6ce	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3763.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
3de2a008-8606-4366-8e7d-82f83dec61ed	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3763.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:02
72940a61-63a8-435a-b4be-1006a8174f54	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3765.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
1d43d6e8-ebe3-4781-807d-a72f7d02dc89	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3765.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
52ac60d6-9f8c-4524-9e76-7f6126e1ffac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 49.0 cm	f	1970-01-01 08:00:07
3418acfb-4403-4314-8c62-1d58c2c44e95	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 49.0 cm	f	1970-01-01 08:00:07
b0268804-e98a-4c8c-8640-cf5b55a20b23	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3766.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
7818ddf5-0e94-4a9e-b58d-c77470898a1a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3766.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
cdb71329-a300-4799-ade4-a334cf07cf57	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:12
699c0322-ef01-4ad9-8ed2-9d72197b4b3c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:12
7849511f-c2aa-4129-8524-80736bdc20ea	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3762.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
2d6c7e76-9ec7-4bf7-82ad-35564c07ca59	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3762.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
34883ad7-716c-48d8-8584-1c417bfab2f4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:17
18840858-89d3-4ea0-a739-095b5827e58c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:17
cef56e15-0c6d-4bcf-972d-8030a7ca50b1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3760.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
c1d16082-e1b6-4563-bdb9-76ef97afce4a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3760.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
ab36049f-a419-41d4-a127-e266616a4d67	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:22
0095878c-61db-47c6-bbb2-08fae7c8b78e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:22
1e0afaa1-2411-4beb-ae34-5544beb4438d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3766.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
43f4143a-9800-4c4b-96bc-e6e9fe6f131c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:27
3036639e-d534-4c0e-b37f-48dd8f463f2f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3766.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
ece3e7fb-4e55-4daa-970c-2fd9064347e7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:27
1a0bb7d3-a402-4bd4-adb3-112e1e178ff0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3767.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
aa2f9be1-78b8-4e9f-bfe9-acb7e8691ede	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:32
6c6c5890-a559-4239-b56f-2cb4ad7079a7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3785.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
3c59d1de-7fae-4445-9ee8-88fbec51477d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3777.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
16273257-2dd5-4f92-bd35-d8b6fc7cd557	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3779.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
96017287-fbb0-431a-aa02-0c14d32fc752	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3792.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
10d55f67-a78e-47c8-b161-ac653925d5cb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3783.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
a2bbc25b-85f9-4302-b209-b6f913b57e42	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 69.0 cm	f	1970-01-01 08:00:17
b7171ce9-ad70-4093-aecc-b3b0612d2310	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3825.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
87774cd0-e611-44c5-b87f-890c94acace3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:22
a70eb167-c9b3-4188-b465-212289725eb7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3775.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
d005d3f1-a891-4713-96d7-69c25a08b149	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:27
077443d8-a5bb-4c45-8941-ef55b299168d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3773.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
db300daa-a11a-4c49-999f-85f6ac8e4783	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:32
2c780577-cb5b-48b2-b77b-53ea98458a52	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3775.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
a528826a-0c94-4209-9aed-3aabbc808e18	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:37
1f5b2b34-4617-455d-8218-10625d4f32c3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3787.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
85f59b38-3ae6-4650-80ae-2b1071ae762e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:42
aae17abf-a4eb-4368-8a5e-65802bab61db	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3776.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
4c9921b0-b3e0-4e88-a176-473592d93124	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:47
0eeb02a8-a791-45cc-886b-905ccbb1e143	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3759.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:52
15b25ac8-8cb6-40b3-be26-597450569e16	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:52
1b4f4da9-29ec-4ae8-92ae-a784f4d561ad	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3783.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
dd972478-4d12-47ad-9a3f-475f46c522e8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:58
05e51794-1269-42fb-ba57-0f274cb76b7d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3769.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
6bfc8aaf-3798-490d-b645-d43353d5e743	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:03
f19af880-4966-4f01-af9e-ced5fad03e7d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3773.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
eaca2e9d-e44e-4664-9ce1-a6a8e19118be	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:08
f44b4271-e9d1-435b-b05b-5074b8bc8267	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3755.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
642b9601-1f32-4f59-8d7d-b3683a122052	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:13
7ba10cd6-2564-4f2c-b636-46cb28fbcfc2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3778.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
d920689b-0602-4d81-8c1e-e4ed6211ae81	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:18
7d73c927-8640-4117-84f7-39613892b2d7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3772.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
31267f10-5b75-4241-a857-caae0410ee5f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3777.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
eae4b7db-72d4-440e-a698-75bf001aa553	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3767.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
f1b93608-60d0-4580-b8fa-b5f6c3954041	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:32
e362654c-34d6-4062-853f-b4dda5480ae0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3785.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
88f35e54-46d3-4c60-bb19-87534f7b146f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3777.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
3cac1620-7a23-4c3c-ac99-dd23db4cca82	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3779.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
a2bccc55-d26a-46c4-88cb-1a62d65d56c2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3792.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
12d561bb-1edb-426c-aaa0-ab9e4593be5b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3783.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
4137751b-fd62-485c-9648-ced43c483372	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 69.0 cm	f	1970-01-01 08:00:17
244fe319-86f5-4e15-91c0-af616899a242	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3825.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
db322c3c-5c2b-48fb-afc8-ea8678b3bc37	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:22
7d79f826-6e38-4573-b6f4-54d9e1c06e37	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3775.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
a1005f5a-4e41-4659-a4e3-e7d3bb46767c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:27
9e140433-9f18-4201-ae88-376616d6ec2c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3773.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
9ca639ff-8fbf-4a9d-8f9d-df3e481b59cb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:32
11ca9c95-4af2-49b4-9848-3983aa68c8e5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3775.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
63580705-5bcb-4d8e-925c-df638a5a7198	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:37
854206bc-ff83-4eb2-b1f8-c18afdb22692	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3787.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
7f1e860f-334e-4b96-9261-be6559ae9d1b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:42
7c4402e4-b0e6-4897-8ebc-98bc60ffb4ac	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3776.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
8dcf8387-5fb7-43b0-9ff7-3ea5d827bc6a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:47
6ed18109-485c-4601-878f-c4006c1428b3	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3759.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:52
40012629-d96c-4637-978e-d62e01f6602d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:52
39da8c11-08f1-4c77-be41-7bb6651a5918	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3783.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
f57f28da-e868-4591-811d-31830b3c6a81	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:58
4732dc0b-5b4f-49ee-8714-c9fce84bde5e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3769.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
31b4e2fe-edf3-4047-bed5-81f5352d6dc6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:03
0d60b84f-c604-4d93-8735-c34d5972ff37	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3773.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
31d6c2b0-7d14-45e3-90f3-9b2ea3eaa1d9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:08
0287609b-3b26-495c-8e14-8a56b574654e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3755.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
2744ac16-16be-4e13-8704-0eeced7bccec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:13
8f91316c-4502-4c8f-b369-0129d87aac49	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3778.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
1a1fbb9b-2121-4cf4-8489-fc67d375acab	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:18
52cac97b-69b4-4ccd-b726-5d5a4189d17d	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3772.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
30929893-36dd-4146-aeb2-e2ea48bf7403	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3777.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
d1d7a67a-fb7b-4b77-b1e9-1761714dd1fb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3764.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
10a72359-3202-475a-9d70-96ff8a46a22e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3764.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:07
8c3b4afd-f916-4a70-bd63-29593c9ea93b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 188.0 cm	f	1970-01-01 08:00:07
0dc4ed86-3a64-4782-b8c7-550ffd7dc9dc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 188.0 cm	f	1970-01-01 08:00:07
d908b368-7ca3-42c7-9fd6-8a48a0a44db2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3767.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
3724c3ec-eca9-43f4-84e9-cefbcc26039c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3767.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
e7bbad2d-d7ef-4cc6-89a0-c88bb5e5e17c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:12
ffddcefe-2b6a-42b3-bfb3-21c6beeb0af5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:12
5f20932d-a4dd-40b0-abd5-2c06dd8e3993	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3774.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
e738ef9f-a21a-443f-b72d-8af4ce12f868	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:17
38e6dfac-0fac-48be-95cb-9ee69c1dd925	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3775.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
79ff260a-b751-49db-bb53-4121201714f9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:22
747459a5-2055-4eef-bed2-f9fce88d438a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3771.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
7cc94fae-40f6-4c37-9c0c-8fe464205140	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:27
de529862-3fdd-4ba6-8152-85d6087b74de	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3771.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
7f0898c7-166f-42e3-93ef-4a860d458bf0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:32
368f09ac-c012-40e3-8d47-0975bf2774a8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3783.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
cdd7be0f-aad9-48dc-b701-708a628b3ce7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:37
590539cf-4197-481d-b96c-e4f4bf999165	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3790.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
8f446507-0734-4126-abc7-55fd374ffad8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:42
1bfcab2a-2ef0-4c48-be06-0386f4071402	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3787.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:48
ae50b85f-eb76-4306-8efe-df4ac1b4787a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:48
5413fd6a-d55d-4760-b6ae-df0f1e251445	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3805.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
10e18d21-4ed2-4ba9-8ba4-1c8db82e25ed	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:53
f8e3073e-ee7d-42e4-9d18-4ecd2cac96d9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3795.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
62f6f157-b7ec-429b-ae6f-a52885ec24b9	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:58
481afda6-0ec5-488d-83a4-aeb39331a76e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3799.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
58f7df9f-de3b-4cf9-99da-d4b7bc1104c6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:03
d2d15fc8-7d79-4f4f-9576-131b239b7c03	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3779.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
d2669766-e084-4bcf-a8c0-69ee7b9ccc78	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:08
56eab48e-d4db-46ae-a332-f26a086e2dd2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3791.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
134d3331-d009-4652-8f0d-5398c23b43f2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:13
9bb05b7d-fe77-4fe2-b5b2-ee589411f015	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3774.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
5782d575-0d45-4f61-9df3-17b0ff623ed5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:17
b30a9211-f307-4d7e-8daf-593855a43bec	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3775.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
a54eb1c1-0f62-47f7-93c7-43908dfe7e1a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:22
6f55ac4d-45ac-4c02-817e-3fc3d180a7c6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3771.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
1c99e519-85bd-4449-b6d9-4c7c483ecc7c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:27
ac7fb172-c5d0-4929-b9b2-dd1eee1af7a1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3771.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
29a5dda3-6724-4b35-909f-a8429e0fbc7b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:32
14232a05-51c7-4e21-9013-c7c45692ae66	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3783.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
17359286-5975-4551-b663-ddf98280dbeb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:37
557a1aa0-2e6d-4440-b4c9-0db428be873f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3790.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
13626b29-6687-4bbb-83dd-50800970e91e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:42
6229bfc9-5742-43d9-9eaa-d30f63f7fd50	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3787.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:48
0509ea6e-ed49-42a1-bcf1-7b895491349b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:48
52ecfacc-34f0-4e42-965e-2890077c0ed0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3805.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
d96f980b-6fab-49c1-b4cf-4678f5c5250c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:53
3b53973c-21a5-4bbd-9aef-b875757b3957	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3795.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:58
bc7e488a-34d1-429b-8191-7369a7e41d0c	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:00:58
fb5ebe33-3bb1-430c-bdb1-9b5547657705	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3799.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:03
88f208e9-5fad-4a22-b3f3-40adc8c053d0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:03
f3fb7b23-39e6-4f48-b76e-2b7bc7d270a0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3779.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
b407a4b6-997e-466f-b61b-c97d694b8a9e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:08
a6ef0d50-44a5-480a-b3e6-b913a6a5ad64	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3791.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
915a6fd2-3837-48b0-9766-40c3c9343b27	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:13
411b5734-9743-43a4-b873-7221dbb96694	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3802.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
6f40403d-28fc-481a-bf15-d69569b31e01	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3802.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
282de4cf-3ad7-41cc-9825-090f39a8154a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3814.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
f337b212-519f-446f-91b2-8126289f163a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3814.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
899ee393-f677-4bec-be5c-03ca1c4c38d4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3775.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
1da60036-2344-4c22-9ab4-ad9abab36cab	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3775.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:37
b31622ec-3c8d-46aa-b086-afb98f5d9af4	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3791.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
480d1d4c-a83b-47e2-ab6c-5a8542ba80a5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3791.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:42
406407c7-4b09-455b-ac66-6c5fc07c3dc1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3773.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
6b7d7bf4-4018-4ff2-aecf-88bb91a37de7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3773.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:47
8ac398be-3f1d-46b8-94a7-f5c64bdc36f8	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3787.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
73fe7154-4a68-4c0e-8dbe-21b7787dc9fb	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3787.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:53
c85428cf-9633-4943-b346-dcc73a806a6a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3795.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
0cd7520a-04cd-4f17-91c2-ab89e7df3f4f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3795.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
6e42fbcd-c5ba-4db2-ba62-b732d112eb2b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3786.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
08efa47c-cdf3-4848-85bd-d94eb77afb3a	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3786.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:23
a5e286d7-0094-40b2-8030-5b101fbb3ed0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Device led: Status Changed	Device led set to on	f	2025-04-27 10:18:50
dc2fb511-96af-46d0-ab42-59377804307e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3777.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
a486a1cd-f106-48d1-aa4b-ca861bdc1ef1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3777.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:33
09d03a26-2f80-4365-bfb6-8ba238431e57	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3783.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:49
7c1068ca-70b6-4cf3-86cd-45f3c5fcdbb6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3783.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:49
6f5f9517-3e1f-43ba-bce2-9a707d4f6a25	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3776.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
0b271ce8-1efb-464b-b3f3-91cd9311b394	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3776.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
05348168-1051-4d27-991c-342883030d4f	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3777.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
c8148830-0e35-4749-a28d-ac587d3c00d5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3777.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:12
57949f39-20dd-479a-822f-f448af445e81	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3773.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
f621eaa2-dc7f-45d2-8fd6-8e65ca0d00a2	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3773.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:17
d447bcf6-4f24-4352-b2cc-f66e78602be1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3775.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
a191f7f4-497d-46c8-abc8-67c854dca265	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3775.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:22
09f52835-4b1c-41df-94a3-071b885169ef	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3789.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
e51f7d29-41c3-40d6-bf42-794b257cfc71	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3789.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:27
a4120e96-cbe4-41ba-bd35-7a279d106c43	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3783.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
be50eaab-2545-4b4f-b835-437c25ebb1b7	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3783.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:32
23cd7617-c3de-4555-b347-dadddd0cdeb1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3789.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
ce9baf7f-7448-48a0-a5a4-7388d6025c79	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3789.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:01
15ae3e80-fef7-4769-8eb2-24c4efb0f3c6	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3800.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
95645bea-9d6d-4807-bd99-16804ae68086	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3800.0 lux. Consider reducing light exposure.	f	1970-01-01 08:00:06
f67d4114-112c-4c21-91f3-2a15117b214e	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3763.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
65d9bb5a-8089-4429-a893-17ea13d6de12	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3763.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:08
0057b5f2-610b-4b95-a092-be6831f9eed1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:08
8498a7b6-7991-4651-9c8f-b1141f38eba5	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:08
9ac3fb8e-7b29-4704-b9d0-5d29478149bd	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3760.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
95c36fbd-a043-4a69-8ae4-bccf48e718b0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3760.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:13
7e0d1412-3665-4675-a148-84c28d9ed22b	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:13
989302de-a7b4-4acc-a6b9-0fca750467aa	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:13
534a7b4e-e0bc-45b1-bc40-10eb6c0af7d0	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3762.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
ce9d6d28-518a-4ca8-b536-48973449c913	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: High Light Intensity Alert	High light intensity detected: 3762.0 lux. Consider reducing light exposure.	f	1970-01-01 08:01:18
ab20bd08-d077-49da-85c1-cb6c1b1b7b36	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:18
9a1deef8-f7f1-4576-9a3f-933924b547d1	d1a2db75-51d8-4b7d-a380-51a8b3d06628	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	notification	Cage: Water Refill Detected	Water refill detected: distance = 357.0 cm	f	1970-01-01 08:01:18
\.


--
-- Data for Name: otp_requests; Type: TABLE DATA; Schema: public; Owner: minhtam
--

COPY public.otp_requests (id, user_id, otp_code, expires_at, is_used, created_at) FROM stdin;
550e8400-e29b-41d4-a716-446655440020	550e8400-e29b-41d4-a716-446655440000	123456	2025-04-01 10:30:00	f	2025-04-01 10:00:00
550e8400-e29b-41d4-a716-446655440021	550e8400-e29b-41d4-a716-446655440002	789012	2025-04-02 09:30:00	t	2025-04-02 09:00:00
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: minhtam
--

COPY public.refresh_tokens (id, user_id, token, expires_at, created_at) FROM stdin;
550e8400-e29b-41d4-a716-446655440010	550e8400-e29b-41d4-a716-446655440000	refresh_token_1	2025-05-01 10:00:00	2025-04-01 10:00:00
550e8400-e29b-41d4-a716-446655440011	550e8400-e29b-41d4-a716-446655440001	refresh_token_2	2025-05-01 11:00:00	2025-04-01 11:00:00
ea77637d-9264-43dc-a406-1f32b7c06c82	f09e2f4d-0da7-42df-9d83-418813e2b5d1	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDYyNDU3ODAsInJvbGUiOiJhZG1pbiIsInVzZXJfaWQiOiJmMDllMmY0ZC0wZGE3LTQyZGYtOWQ4My00MTg4MTNlMmI1ZDEifQ.qkyCck6w5AYYY6eHNuSzK-ueb69Am8T2OJcLPD4WbUo	2025-05-03 11:16:20.222139	2025-04-26 11:16:20.222364
d7642431-9822-4f33-9f44-40ac259ed4cc	d1a2db75-51d8-4b7d-a380-51a8b3d06628	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NDYyNzgwNTgsInJvbGUiOiJ1c2VyIiwidXNlcl9pZCI6ImQxYTJkYjc1LTUxZDgtNGI3ZC1hMzgwLTUxYThiM2QwNjYyOCJ9.Hto0nhSC3J5L4ffRcIeJ0_A--mbIMl8lOPO-ZCNRxmk	2025-05-03 20:14:18.882181	2025-04-26 20:14:18.882453
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: minhtam
--

COPY public.schema_migrations (version, dirty) FROM stdin;
9	f
\.


--
-- Data for Name: sensors; Type: TABLE DATA; Schema: public; Owner: minhtam
--

COPY public.sensors (id, name, type, value, unit, cage_id, created_at, updated_at) FROM stdin;
00000000-0000-0000-0000-000000000001	temperature	temperature	30.41973	°C	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	2025-04-25 14:34:43.708422	1970-01-01 08:00:17
00000000-0000-0000-0000-000000000002	humidity	humidity	67.02404	%	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	2025-04-25 14:34:43.708422	1970-01-01 08:00:17
00000000-0000-0000-0000-000000000003	light	light	3697	lux	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	2025-04-25 14:34:43.708422	1970-01-01 08:00:17
00000000-0000-0000-0000-000000000004	water-level	distance	345		8d05bb9a-0ef1-4679-9d89-13b1be1ca219	2025-04-25 14:34:43.708422	1970-01-01 08:00:17
\.


--
-- Data for Name: settings; Type: TABLE DATA; Schema: public; Owner: minhtam
--

COPY public.settings (cage_id, high_water_usage_threshold, created_at, updated_at) FROM stdin;
550e8400-e29b-41d4-a716-446655440100	1000	2025-04-01 12:00:00	2025-04-01 12:00:00
550e8400-e29b-41d4-a716-446655440101	800	2025-04-02 08:00:00	2025-04-02 08:00:00
550e8400-e29b-41d4-a716-446655440102	1200	2025-04-01 13:00:00	2025-04-01 13:00:00
\.


--
-- Data for Name: statistics; Type: TABLE DATA; Schema: public; Owner: minhtam
--

COPY public.statistics (id, cage_id, water_refill_sl, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: minhtam
--

COPY public.users (id, username, email, avatar_url, password_hash, otp_secret, is_email_verified, role, created_at, updated_at) FROM stdin;
550e8400-e29b-41d4-a716-446655440000	john_doe	john.doe@example.com	https://example.com/avatar1.jpg	$2a$10$examplehash1	secret1	t	user	2025-04-01 10:00:00	2025-04-01 10:00:00
550e8400-e29b-41d4-a716-446655440001	jane_smith	jane.smith@example.com	https://example.com/avatar2.jpg	$2a$10$examplehash2	secret2	t	admin	2025-04-01 11:00:00	2025-04-01 11:00:00
550e8400-e29b-41d4-a716-446655440002	bob_jones	bob.jones@example.com		$2a$10$examplehash3	secret3	f	user	2025-04-02 09:00:00	2025-04-02 09:00:00
3d532266-888b-4895-ade2-c0bb4569ca0a	user2	user2@example.com		$2a$10$z7X8Y9Z0W1Q2R3S4T5U6V7W8X9Y0Z1A2B3C4D5E6F7G8H9I0J1K2	\N	f	user	2025-04-25 12:37:07.987723	2025-04-25 12:37:07.987723
d1a2db75-51d8-4b7d-a380-51a8b3d06628	user1	user1@example.com		$2a$10$y3NJ60RMNse6SX14LGAVLOhqBi5cZKrTSr3ydVQo/gRNc2jRLFVKK	\N	f	user	2025-04-25 12:27:01.511737	2025-04-25 12:45:26.950734
f09e2f4d-0da7-42df-9d83-418813e2b5d1	admin1	admin1@example.com		$2a$10$EDDWU0p.MXHBIc166fW.pOkNuccnqz8ahCopr/Sq1iOFhVkU6cmZy	\N	t	admin	2025-04-25 13:33:41.804552	2025-04-25 13:33:41.804552
\.


--
-- Data for Name: water_refills; Type: TABLE DATA; Schema: public; Owner: minhtam
--

COPY public.water_refills (id, cage_id, water_refill_sl, created_at, updated_at) FROM stdin;
65c8d3b6-5496-406a-bd5e-4f2589fe14b9	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:58	1970-01-01 08:00:58
569f327c-02e6-401a-84fa-b7d15afdd4c5	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:58	1970-01-01 08:00:58
76020e81-e311-44c7-9153-791dd9938ec1	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:39	1970-01-01 08:01:39
9d77ceba-955b-4499-be6d-12d25b488f3a	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:39	1970-01-01 08:01:39
677dc654-9bb1-4f97-8650-a5ae7fdff3b1	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:12	1970-01-01 08:00:12
f23280ff-a6d3-439e-b1ed-e81e1a469d2b	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:12	1970-01-01 08:00:12
d64a9f6e-1923-4339-b005-66a3875521df	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:32	1970-01-01 08:00:32
23916839-556b-42a9-a699-f177b402629d	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:32	1970-01-01 08:00:32
b0654fa4-625d-4de6-b788-5a921d84c51e	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:37	1970-01-01 08:00:37
800d4e9f-cfa7-4f21-944a-9ffa1e76f00d	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:37	1970-01-01 08:00:37
141a03f2-be60-45b8-9eed-b97eeb1b9688	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:07	1970-01-01 08:00:07
abaf3610-30ab-45e6-a6cf-89fef654671b	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:07	1970-01-01 08:00:07
039d42ce-0761-4590-b78a-92846bc11d08	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:12	1970-01-01 08:00:12
45a2deea-6321-416c-99bf-27ee296194dd	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:12	1970-01-01 08:00:12
11c11232-a19c-44e2-a438-ebbb7e4ca73c	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:17	1970-01-01 08:00:17
6ab3fc5f-d67c-45c3-bbdc-0039fb795880	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:17	1970-01-01 08:00:17
a52381be-b9d8-4742-8ed6-6d9652931d51	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:22	1970-01-01 08:00:22
454ac4d6-3a04-4fd0-9321-c814d85f15d4	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:22	1970-01-01 08:00:22
fe96eebd-5555-428d-ba84-5c28ccccec0f	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:27	1970-01-01 08:00:27
f269237a-8c69-4c49-9b17-15051f3a14cd	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:27	1970-01-01 08:00:27
350ed452-503e-49e3-a25a-15938f60797d	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:32	1970-01-01 08:00:32
2a0b010b-3560-4d78-a58b-36d29c1aa53c	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:32	1970-01-01 08:00:32
744e6a05-4afe-47b2-a014-39249aec05c4	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:17	1970-01-01 08:00:17
a043361d-98e2-49b9-a7d7-c001e9bce891	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:17	1970-01-01 08:00:17
620ea2ea-88dc-4904-9aac-9050f8195343	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:22	1970-01-01 08:00:22
ff98ff95-ccde-42b5-a0f3-8fa2f26ca19e	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:22	1970-01-01 08:00:22
468323cf-8c0b-41de-bad3-bf83da09b82e	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:27	1970-01-01 08:00:27
4d27bc63-f9b0-48ec-a3c7-935e27fb581e	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:27	1970-01-01 08:00:27
6e0d8699-6c08-43ac-9e90-bbecb2154815	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:32	1970-01-01 08:00:32
8c63a92e-6989-45e9-a1ee-ee0203d29ae3	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:32	1970-01-01 08:00:32
bbce6f7d-e039-465d-8c36-06eb49520342	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:37	1970-01-01 08:00:37
900b31a3-2ec8-4dcc-ab4b-1858258af715	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:37	1970-01-01 08:00:37
5e493a8d-603e-4e05-a075-9f01446f3f3f	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:42	1970-01-01 08:00:42
f3fc2626-ded9-435d-9635-bca37f72e63d	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:42	1970-01-01 08:00:42
fe162869-1063-4f4a-bbe7-ec3b6be35611	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:47	1970-01-01 08:00:47
0ee3ab0e-e529-4817-aacd-63be125bf1b9	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:47	1970-01-01 08:00:47
223097e8-d56b-49f4-a047-e8728f54fcc0	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:52	1970-01-01 08:00:52
b1d72157-0a9e-4c3a-9774-2f400ec554a9	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:52	1970-01-01 08:00:52
ada45c1f-03b7-4116-952b-13cd07e87089	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:58	1970-01-01 08:00:58
13c4d89e-ccf3-486e-b6b4-5bf102abba05	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:58	1970-01-01 08:00:58
d5144782-03bd-4a6d-ba4c-9fd2b594965a	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:03	1970-01-01 08:01:03
ae92eda8-3f3b-4c22-a4ae-5b58e23ec3b9	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:03	1970-01-01 08:01:03
0c3e816d-80ea-411b-b074-d4182854d656	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:08	1970-01-01 08:01:08
0762594c-f2e8-4cb5-aa30-0e41b29092d0	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:08	1970-01-01 08:01:08
e238375f-e3b6-4895-b35f-bc94306ad6d2	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:13	1970-01-01 08:01:13
b19f3a22-46f5-4421-84b2-e468e13ecfd0	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:13	1970-01-01 08:01:13
319132b5-645a-4841-8a9b-e940cc8eefde	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:18	1970-01-01 08:01:18
e0445123-5e07-460d-b5c3-51745e4619ab	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:18	1970-01-01 08:01:18
c70db5cb-5c15-4b05-b40b-3940d173ce9a	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:07	1970-01-01 08:00:07
d0954b3a-ca9f-417e-a3f7-507845b71774	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:07	1970-01-01 08:00:07
6c0bd5c9-da60-47fd-bf12-2d4b9ea19762	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:12	1970-01-01 08:00:12
6352e87a-e06a-488a-8155-9fdf57758acf	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:12	1970-01-01 08:00:12
9b94f2de-1e40-40e4-912a-4a06f2dd9567	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:17	1970-01-01 08:00:17
a6d60915-3075-4b14-a13f-98e24a8c72fd	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:17	1970-01-01 08:00:17
17eafc49-028b-4954-8313-9eaf6f029a3f	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:22	1970-01-01 08:00:22
b6b719b5-0170-4c07-aa00-92ab13a91e50	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:22	1970-01-01 08:00:22
9ae0d48f-4588-47c5-aafe-f125ec1e6eb9	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:27	1970-01-01 08:00:27
caa45d4d-986f-4a6b-90f8-7cf478cee080	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:27	1970-01-01 08:00:27
5c517116-b0fd-4382-9d7b-4d267d66e59d	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:32	1970-01-01 08:00:32
5aaea2e0-2cb4-4979-acd4-8ece309ca394	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:32	1970-01-01 08:00:32
ad4a29c8-961f-447e-b65c-8f04c3235962	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:37	1970-01-01 08:00:37
c42dcb73-6c0d-4e27-8bd7-7cfc01e3c194	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:37	1970-01-01 08:00:37
8a1c2a83-9912-4e29-a29a-7a4807e5f6f0	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:42	1970-01-01 08:00:42
b45615f5-4060-47b3-a936-e9a5270f78ae	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:42	1970-01-01 08:00:42
d987675c-408e-43a6-99f7-4d47a2f2f0a3	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:48	1970-01-01 08:00:48
2f9a929e-6260-4fab-b896-ed611bb933b6	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:48	1970-01-01 08:00:48
b0e41080-bac6-4b32-94cf-c4b8f7af2dbc	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:53	1970-01-01 08:00:53
db8e6fec-a38b-4b3a-b47e-827120f2ec8f	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:53	1970-01-01 08:00:53
19b4592c-2a48-47dc-9d29-bc6367b22164	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:58	1970-01-01 08:00:58
6be97e7a-40bb-4186-ad71-e2afa1db29ef	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:00:58	1970-01-01 08:00:58
6db7bd83-48f2-4546-93d4-02861a56ad37	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:03	1970-01-01 08:01:03
c9bc17e6-cd84-4a71-bdc7-3891baa61cf4	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:03	1970-01-01 08:01:03
2fb98f7b-9f11-4269-8be7-5450c80ffa86	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:08	1970-01-01 08:01:08
79590cfd-0641-4cc6-8d4c-59bdcd31a95f	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:08	1970-01-01 08:01:08
7fe872d8-827e-40bb-825a-ca5a92d5cf2a	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:13	1970-01-01 08:01:13
44498a99-f149-4b73-87cc-e86d1a699b6d	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:13	1970-01-01 08:01:13
6a070175-37a4-4237-b479-6dd715aac9ab	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:13	1970-01-01 08:01:13
dd01f9a8-abf2-4048-b230-670ea0f4d0d6	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:18	1970-01-01 08:01:18
dcde695e-ee4d-469d-8f9c-ad6aa7c80b2f	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:13	1970-01-01 08:01:13
22fe4adb-7e50-41b6-9044-a644e814cd15	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:18	1970-01-01 08:01:18
a5ae0d55-1960-426f-a630-af9f97dbdaa7	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:08	1970-01-01 08:01:08
a9b84f68-a558-4218-9a68-95eb1c4134bb	8d05bb9a-0ef1-4679-9d89-13b1be1ca219	1	1970-01-01 08:01:08	1970-01-01 08:01:08
\.


--
-- Name: automation_rules automation_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.automation_rules
    ADD CONSTRAINT automation_rules_pkey PRIMARY KEY (id);


--
-- Name: cages cages_pkey; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.cages
    ADD CONSTRAINT cages_pkey PRIMARY KEY (id);


--
-- Name: devices devices_name_key; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_name_key UNIQUE (name);


--
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: otp_requests otp_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.otp_requests
    ADD CONSTRAINT otp_requests_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sensors sensors_pkey; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.sensors
    ADD CONSTRAINT sensors_pkey PRIMARY KEY (id);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (cage_id);


--
-- Name: statistics statistics_pkey; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.statistics
    ADD CONSTRAINT statistics_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: water_refills water_refills_pkey; Type: CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.water_refills
    ADD CONSTRAINT water_refills_pkey PRIMARY KEY (id);


--
-- Name: idx_automation_rules_device_id; Type: INDEX; Schema: public; Owner: minhtam
--

CREATE INDEX idx_automation_rules_device_id ON public.automation_rules USING btree (device_id);


--
-- Name: idx_automation_rules_sensor_id; Type: INDEX; Schema: public; Owner: minhtam
--

CREATE INDEX idx_automation_rules_sensor_id ON public.automation_rules USING btree (sensor_id);


--
-- Name: idx_cages_user_id; Type: INDEX; Schema: public; Owner: minhtam
--

CREATE INDEX idx_cages_user_id ON public.cages USING btree (user_id);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: minhtam
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_sensors_cage_id; Type: INDEX; Schema: public; Owner: minhtam
--

CREATE INDEX idx_sensors_cage_id ON public.sensors USING btree (cage_id);


--
-- Name: idx_statistic_cage_id; Type: INDEX; Schema: public; Owner: minhtam
--

CREATE INDEX idx_statistic_cage_id ON public.statistics USING btree (cage_id);


--
-- Name: idx_statistic_created_at; Type: INDEX; Schema: public; Owner: minhtam
--

CREATE INDEX idx_statistic_created_at ON public.statistics USING btree (created_at);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: minhtam
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: automation_rules automation_rules_cage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.automation_rules
    ADD CONSTRAINT automation_rules_cage_id_fkey FOREIGN KEY (cage_id) REFERENCES public.cages(id) ON DELETE CASCADE;


--
-- Name: cages cages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.cages
    ADD CONSTRAINT cages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: devices devices_cage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_cage_id_fkey FOREIGN KEY (cage_id) REFERENCES public.cages(id) ON DELETE CASCADE;


--
-- Name: water_refills fk_cage; Type: FK CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.water_refills
    ADD CONSTRAINT fk_cage FOREIGN KEY (cage_id) REFERENCES public.cages(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_cage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_cage_id_fkey FOREIGN KEY (cage_id) REFERENCES public.cages(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: otp_requests otp_requests_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.otp_requests
    ADD CONSTRAINT otp_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: sensors sensors_cage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.sensors
    ADD CONSTRAINT sensors_cage_id_fkey FOREIGN KEY (cage_id) REFERENCES public.cages(id) ON DELETE CASCADE;


--
-- Name: settings settings_cage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_cage_id_fkey FOREIGN KEY (cage_id) REFERENCES public.cages(id) ON DELETE CASCADE;


--
-- Name: statistics statistics_cage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: minhtam
--

ALTER TABLE ONLY public.statistics
    ADD CONSTRAINT statistics_cage_id_fkey FOREIGN KEY (cage_id) REFERENCES public.cages(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

