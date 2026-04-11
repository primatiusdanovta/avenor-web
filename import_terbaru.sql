--
-- PostgreSQL database dump
--

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: account_payables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_payables (
    id bigint NOT NULL,
    account_payable character varying(255) NOT NULL,
    due_date date NOT NULL,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    store_id bigint
);


--
-- Name: account_payables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_payables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_payables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_payables_id_seq OWNED BY public.account_payables.id;


--
-- Name: account_receivables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_receivables (
    id bigint NOT NULL,
    consignment_id bigint,
    receivable_name character varying(255) NOT NULL,
    place_name character varying(255) NOT NULL,
    consignment_date date NOT NULL,
    due_date date NOT NULL,
    total_value numeric(14,2) DEFAULT '0'::numeric NOT NULL,
    items_summary text,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    consigned_value numeric(14,2) DEFAULT '0'::numeric NOT NULL,
    status character varying(255) DEFAULT 'dititipkan'::character varying NOT NULL,
    store_id bigint
);


--
-- Name: account_receivables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_receivables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_receivables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_receivables_id_seq OWNED BY public.account_receivables.id;


--
-- Name: areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.areas (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    region character varying(255) NOT NULL,
    target_visits integer DEFAULT 20 NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: areas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.areas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.areas_id_seq OWNED BY public.areas.id;


--
-- Name: articles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.articles (
    id bigint NOT NULL,
    title character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    author character varying(255),
    published_at date,
    excerpt character varying(500) NOT NULL,
    body text NOT NULL,
    image_path character varying(255),
    is_published boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    seo_title character varying(255),
    seo_description character varying(500),
    seo_keywords character varying(1000),
    seo_canonical_url character varying(2048),
    seo_robots character varying(255),
    og_title character varying(255),
    og_description character varying(500),
    og_image_url character varying(2048),
    og_image_alt character varying(255),
    category character varying(255)
);


--
-- Name: articles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.articles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: articles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.articles_id_seq OWNED BY public.articles.id;


--
-- Name: attendances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendances (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    attendance_date date NOT NULL,
    check_in time(0) without time zone NOT NULL,
    check_out time(0) without time zone,
    status character varying(20) NOT NULL,
    notes text,
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    check_in_latitude numeric(10,7),
    check_in_longitude numeric(10,7),
    check_out_latitude numeric(10,7),
    check_out_longitude numeric(10,7),
    store_id bigint,
    CONSTRAINT attendances_status_check CHECK (((status)::text = ANY ((ARRAY['hadir'::character varying, 'terlambat'::character varying, 'izin'::character varying, 'sakit'::character varying])::text[])))
);


--
-- Name: attendances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attendances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attendances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attendances_id_seq OWNED BY public.attendances.id;


--
-- Name: cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cache (
    key character varying(255) NOT NULL,
    value text NOT NULL,
    expiration integer NOT NULL
);


--
-- Name: cache_locks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cache_locks (
    key character varying(255) NOT NULL,
    owner character varying(255) NOT NULL,
    expiration integer NOT NULL
);


--
-- Name: career_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.career_applications (
    id bigint NOT NULL,
    job_title character varying(255),
    responses json,
    uploaded_files json,
    status character varying(255) DEFAULT 'submitted'::character varying NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    content_creator_id bigint,
    transferred_to_content_creator_at timestamp(0) without time zone
);


--
-- Name: career_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.career_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: career_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.career_applications_id_seq OWNED BY public.career_applications.id;


--
-- Name: consignment_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consignment_items (
    id bigint NOT NULL,
    consignment_id bigint NOT NULL,
    product_onhand_id bigint NOT NULL,
    product_id bigint NOT NULL,
    product_name character varying(255) NOT NULL,
    pickup_batch_code character varying(255),
    quantity integer NOT NULL,
    sold_quantity integer DEFAULT 0 NOT NULL,
    returned_quantity integer DEFAULT 0 NOT NULL,
    status character varying(255) DEFAULT 'dititipkan'::character varying NOT NULL,
    status_notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: consignment_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.consignment_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consignment_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.consignment_items_id_seq OWNED BY public.consignment_items.id;


--
-- Name: consignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consignments (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    place_name character varying(255) NOT NULL,
    address text NOT NULL,
    consignment_date date NOT NULL,
    submitted_at timestamp(0) without time zone NOT NULL,
    latitude numeric(10,7) NOT NULL,
    longitude numeric(10,7) NOT NULL,
    notes text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    handover_proof_photo character varying(255),
    store_id bigint
);


--
-- Name: consignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.consignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.consignments_id_seq OWNED BY public.consignments.id;


--
-- Name: content_creators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_creators (
    id_contentcreator bigint NOT NULL,
    nama character varying(255) NOT NULL,
    bidang json NOT NULL,
    username_instagram character varying(255),
    username_tiktok character varying(255),
    followers_instagram bigint DEFAULT '0'::bigint NOT NULL,
    followers_tiktok bigint DEFAULT '0'::bigint NOT NULL,
    range_fee_percontent character varying(255),
    jenis_konten character varying(255),
    no_telp character varying(30),
    wilayah character varying(255),
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: content_creators_id_contentcreator_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_creators_id_contentcreator_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_creators_id_contentcreator_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_creators_id_contentcreator_seq OWNED BY public.content_creators.id_contentcreator;


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
    id_pelanggan bigint NOT NULL,
    nama character varying(255),
    no_telp character varying(255),
    tiktok_instagram character varying(255),
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    pembelian_terakhir timestamp(0) without time zone,
    store_id bigint
);


--
-- Name: customers_id_pelanggan_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.customers_id_pelanggan_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customers_id_pelanggan_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.customers_id_pelanggan_seq OWNED BY public.customers.id_pelanggan;


--
-- Name: expenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.expenses (
    id bigint NOT NULL,
    category character varying(255) NOT NULL,
    title character varying(255) NOT NULL,
    amount numeric(15,2) NOT NULL,
    expense_date date NOT NULL,
    notes text,
    created_by bigint,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    store_id bigint
);


--
-- Name: expenses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.expenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: expenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.expenses_id_seq OWNED BY public.expenses.id;


--
-- Name: failed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.failed_jobs (
    id bigint NOT NULL,
    uuid character varying(255) NOT NULL,
    connection text NOT NULL,
    queue text NOT NULL,
    payload text NOT NULL,
    exception text NOT NULL,
    failed_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.failed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.failed_jobs_id_seq OWNED BY public.failed_jobs.id;


--
-- Name: fragrance_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fragrance_details (
    id_fd bigint NOT NULL,
    jenis character varying(255) NOT NULL,
    detail character varying(255) NOT NULL,
    deskripsi text,
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: fragrance_details_id_fd_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fragrance_details_id_fd_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fragrance_details_id_fd_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fragrance_details_id_fd_seq OWNED BY public.fragrance_details.id_fd;


--
-- Name: global_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.global_settings (
    id bigint NOT NULL,
    key character varying(255) NOT NULL,
    value json,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: global_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.global_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: global_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.global_settings_id_seq OWNED BY public.global_settings.id;


--
-- Name: hpp_calculation_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hpp_calculation_items (
    id_hpp_item bigint NOT NULL,
    id_hpp bigint NOT NULL,
    id_rm bigint NOT NULL,
    nama_rm character varying(255) NOT NULL,
    satuan character varying(255) NOT NULL,
    presentase numeric(8,2) NOT NULL,
    harga_satuan numeric(15,2) NOT NULL,
    harga_final numeric(15,2) NOT NULL,
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    total_stock numeric(15,2) DEFAULT '0'::numeric NOT NULL
);


--
-- Name: hpp_calculation_items_id_hpp_item_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hpp_calculation_items_id_hpp_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hpp_calculation_items_id_hpp_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hpp_calculation_items_id_hpp_item_seq OWNED BY public.hpp_calculation_items.id_hpp_item;


--
-- Name: hpp_calculations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hpp_calculations (
    id_hpp bigint NOT NULL,
    id_product bigint NOT NULL,
    total_hpp numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    store_id bigint
);


--
-- Name: hpp_calculations_id_hpp_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hpp_calculations_id_hpp_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hpp_calculations_id_hpp_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hpp_calculations_id_hpp_seq OWNED BY public.hpp_calculations.id_hpp;


--
-- Name: job_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.job_batches (
    id character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    total_jobs integer NOT NULL,
    pending_jobs integer NOT NULL,
    failed_jobs integer NOT NULL,
    failed_job_ids text NOT NULL,
    options text,
    cancelled_at integer,
    created_at integer NOT NULL,
    finished_at integer
);


--
-- Name: jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.jobs (
    id bigint NOT NULL,
    queue character varying(255) NOT NULL,
    payload text NOT NULL,
    attempts smallint NOT NULL,
    reserved_at integer,
    available_at integer NOT NULL,
    created_at integer NOT NULL
);


--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: landing_page_contents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.landing_page_contents (
    id bigint NOT NULL,
    section_name character varying(100) NOT NULL,
    title character varying(255),
    description text,
    image_path character varying(255),
    is_active boolean DEFAULT true NOT NULL,
    meta_data json,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: landing_page_contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.landing_page_contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: landing_page_contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.landing_page_contents_id_seq OWNED BY public.landing_page_contents.id;


--
-- Name: marketing_bonus_adjustments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketing_bonus_adjustments (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_by bigint,
    bonus_month date NOT NULL,
    amount numeric(15,2) NOT NULL,
    note text,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: marketing_bonus_adjustments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.marketing_bonus_adjustments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: marketing_bonus_adjustments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.marketing_bonus_adjustments_id_seq OWNED BY public.marketing_bonus_adjustments.id;


--
-- Name: marketing_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketing_locations (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    latitude numeric(10,7) NOT NULL,
    longitude numeric(10,7) NOT NULL,
    source character varying(20) DEFAULT 'heartbeat'::character varying NOT NULL,
    recorded_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    store_id bigint
);


--
-- Name: marketing_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.marketing_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: marketing_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.marketing_locations_id_seq OWNED BY public.marketing_locations.id;


--
-- Name: marketing_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketing_notifications (
    id bigint NOT NULL,
    created_by bigint,
    title character varying(255) NOT NULL,
    body text NOT NULL,
    target_role character varying(255) DEFAULT 'marketing'::character varying NOT NULL,
    status character varying(255) DEFAULT 'draft'::character varying NOT NULL,
    scheduled_at timestamp(0) without time zone,
    published_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    store_id bigint
);


--
-- Name: marketing_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.marketing_notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: marketing_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.marketing_notifications_id_seq OWNED BY public.marketing_notifications.id;


--
-- Name: migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    migration character varying(255) NOT NULL,
    batch integer NOT NULL
);


--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: mobile_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mobile_access_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    token character varying(64) NOT NULL,
    last_used_at timestamp(0) without time zone,
    expires_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    push_token text,
    push_platform character varying(20),
    push_token_updated_at timestamp(0) without time zone
);


--
-- Name: mobile_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mobile_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mobile_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mobile_access_tokens_id_seq OWNED BY public.mobile_access_tokens.id;


--
-- Name: offline_sales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offline_sales (
    id_penjualan_offline bigint NOT NULL,
    id_user bigint NOT NULL,
    id_product bigint,
    promo_id bigint,
    nama character varying(255) NOT NULL,
    nama_product character varying(255) NOT NULL,
    quantity integer NOT NULL,
    harga numeric(14,2) NOT NULL,
    kode_promo character varying(255),
    promo character varying(255),
    bukti_pembelian character varying(255),
    approval_status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    approved_by bigint,
    approved_at timestamp(0) without time zone,
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_product_onhand bigint,
    id_pelanggan bigint,
    transaction_code character varying(255),
    total_hpp numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    store_id bigint
);


--
-- Name: offline_sales_id_penjualan_offline_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.offline_sales_id_penjualan_offline_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offline_sales_id_penjualan_offline_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.offline_sales_id_penjualan_offline_seq OWNED BY public.offline_sales.id_penjualan_offline;


--
-- Name: online_sale_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.online_sale_items (
    id bigint NOT NULL,
    online_sale_id bigint NOT NULL,
    id_product bigint,
    raw_product_name character varying(255) NOT NULL,
    nama_product character varying(255) NOT NULL,
    quantity integer DEFAULT 0 NOT NULL,
    harga numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    store_id bigint
);


--
-- Name: online_sale_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.online_sale_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: online_sale_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.online_sale_items_id_seq OWNED BY public.online_sale_items.id;


--
-- Name: online_sales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.online_sales (
    id bigint NOT NULL,
    order_id character varying(255) NOT NULL,
    order_status character varying(255),
    order_substatus character varying(255),
    cancelation character varying(255),
    province character varying(255),
    regency_city character varying(255),
    paid_time timestamp(0) without time zone,
    total_amount numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone,
    store_id bigint
);


--
-- Name: online_sales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.online_sales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: online_sales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.online_sales_id_seq OWNED BY public.online_sales.id;


--
-- Name: password_reset_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_reset_tokens (
    email character varying(255) NOT NULL,
    token character varying(255) NOT NULL,
    created_at timestamp(0) without time zone
);


--
-- Name: permission_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permission_roles (
    id bigint NOT NULL,
    key character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    legacy_role character varying(255) NOT NULL,
    description text,
    permissions json NOT NULL,
    is_locked boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: permission_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permission_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permission_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.permission_roles_id_seq OWNED BY public.permission_roles.id;


--
-- Name: product_fragrance_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_fragrance_details (
    id bigint NOT NULL,
    id_product bigint NOT NULL,
    id_fd bigint NOT NULL,
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: product_fragrance_details_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_fragrance_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_fragrance_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_fragrance_details_id_seq OWNED BY public.product_fragrance_details.id;


--
-- Name: product_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_images (
    id bigint NOT NULL,
    product_id bigint NOT NULL,
    image_path character varying(255) NOT NULL,
    sort_order integer DEFAULT 1 NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: product_images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_images_id_seq OWNED BY public.product_images.id;


--
-- Name: product_onhands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_onhands (
    id_product_onhand bigint NOT NULL,
    user_id bigint NOT NULL,
    id_product bigint NOT NULL,
    nama_product character varying(255) NOT NULL,
    quantity integer NOT NULL,
    quantity_dikembalikan integer DEFAULT 0 NOT NULL,
    return_status character varying(255) DEFAULT 'belum'::character varying NOT NULL,
    approved_by bigint,
    assignment_date date NOT NULL,
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    take_status character varying(255) DEFAULT 'disetujui'::character varying NOT NULL,
    take_approved_by bigint,
    take_requested_at timestamp(0) without time zone,
    take_reviewed_at timestamp(0) without time zone,
    approved_return_quantity integer DEFAULT 0 NOT NULL,
    manual_sold_quantity integer DEFAULT 0 NOT NULL,
    pickup_batch_code character varying(255),
    store_id bigint
);


--
-- Name: product_onhands_id_product_onhand_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_onhands_id_product_onhand_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_onhands_id_product_onhand_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_onhands_id_product_onhand_seq OWNED BY public.product_onhands.id_product_onhand;


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id_product bigint NOT NULL,
    nama_product character varying(255) NOT NULL,
    harga numeric(14,2) NOT NULL,
    harga_modal numeric(14,2) NOT NULL,
    stock integer DEFAULT 0 NOT NULL,
    gambar character varying(255),
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deskripsi text,
    landing_page_active boolean DEFAULT false NOT NULL,
    seo_title character varying(255),
    seo_description text,
    canonical_url character varying(255),
    top_notes_text text,
    heart_notes_text text,
    base_notes_text text,
    education_content json,
    faq_data json,
    educational_blocks json,
    landing_theme_key character varying(100),
    landing_seo_fallback_key character varying(100),
    narrative_scroll json,
    bottle_image character varying(255),
    store_id bigint
);


--
-- Name: products_id_product_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.products_id_product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: products_id_product_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.products_id_product_seq OWNED BY public.products.id_product;


--
-- Name: promos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.promos (
    id bigint NOT NULL,
    kode_promo character varying(255) NOT NULL,
    nama_promo character varying(255) NOT NULL,
    potongan numeric(14,2) NOT NULL,
    masa_aktif date NOT NULL,
    minimal_quantity integer DEFAULT 1 NOT NULL,
    minimal_belanja numeric(14,2) DEFAULT '0'::numeric NOT NULL,
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    store_id bigint
);


--
-- Name: promos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.promos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: promos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.promos_id_seq OWNED BY public.promos.id;


--
-- Name: raw_materials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.raw_materials (
    id_rm bigint NOT NULL,
    nama_rm character varying(255) NOT NULL,
    harga numeric(15,2) NOT NULL,
    quantity numeric(15,2) NOT NULL,
    harga_satuan numeric(15,2) NOT NULL,
    stock numeric(15,2) NOT NULL,
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    satuan character varying(255) NOT NULL,
    total_quantity numeric(15,2) DEFAULT 0 NOT NULL,
    harga_total numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    store_id bigint,
    waste_materials numeric(14,2) DEFAULT '0'::numeric NOT NULL,
    waste_percentage numeric(8,2) DEFAULT '0'::numeric NOT NULL,
    waste_loss_percentage numeric(8,2) DEFAULT '0'::numeric NOT NULL,
    waste_loss_amount numeric(14,2) DEFAULT '0'::numeric NOT NULL
);


--
-- Name: raw_materials_id_rm_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.raw_materials_id_rm_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: raw_materials_id_rm_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.raw_materials_id_rm_seq OWNED BY public.raw_materials.id_rm;


--
-- Name: sales_targets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_targets (
    id bigint NOT NULL,
    role character varying(255) NOT NULL,
    daily_target_qty integer DEFAULT 0 NOT NULL,
    daily_bonus numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    weekly_target_qty integer DEFAULT 0 NOT NULL,
    weekly_bonus numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    monthly_target_qty integer DEFAULT 0 NOT NULL,
    monthly_bonus numeric(15,2) DEFAULT '0'::numeric NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: sales_targets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sales_targets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sales_targets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sales_targets_id_seq OWNED BY public.sales_targets.id;


--
-- Name: seo_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.seo_settings (
    id bigint NOT NULL,
    page_key character varying(255) NOT NULL,
    title character varying(255) NOT NULL,
    meta_description text,
    meta_keywords text,
    canonical_url character varying(255),
    og_title character varying(255),
    og_description text,
    og_image character varying(255),
    robots character varying(255) DEFAULT 'index,follow'::character varying NOT NULL,
    schema_json text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: seo_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seo_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seo_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.seo_settings_id_seq OWNED BY public.seo_settings.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    user_id bigint,
    ip_address character varying(45),
    user_agent text,
    payload text NOT NULL,
    last_activity integer NOT NULL
);


--
-- Name: store_user_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store_user_assignments (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    store_id bigint NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: store_user_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.store_user_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: store_user_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.store_user_assignments_id_seq OWNED BY public.store_user_assignments.id;


--
-- Name: stores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stores (
    id bigint NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    display_name character varying(255) NOT NULL,
    status character varying(255) DEFAULT 'active'::character varying NOT NULL,
    timezone character varying(255) DEFAULT 'Asia/Jakarta'::character varying NOT NULL,
    currency character varying(255) DEFAULT 'IDR'::character varying NOT NULL,
    address text,
    settings json,
    created_at timestamp(0) without time zone,
    updated_at timestamp(0) without time zone
);


--
-- Name: stores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.stores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: stores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.stores_id_seq OWNED BY public.stores.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id_user bigint NOT NULL,
    nama character varying(255) NOT NULL,
    status character varying(255) DEFAULT 'aktif'::character varying NOT NULL,
    role character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    remember_token character varying(100),
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    require_return_before_checkout boolean DEFAULT true NOT NULL,
    permission_role_id bigint,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['superadmin'::character varying, 'admin'::character varying, 'marketing'::character varying, 'sales_field_executive'::character varying])::text[])))
);


--
-- Name: users_id_user_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_user_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_user_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_user_seq OWNED BY public.users.id_user;


--
-- Name: account_payables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_payables ALTER COLUMN id SET DEFAULT nextval('public.account_payables_id_seq'::regclass);


--
-- Name: account_receivables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_receivables ALTER COLUMN id SET DEFAULT nextval('public.account_receivables_id_seq'::regclass);


--
-- Name: areas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas ALTER COLUMN id SET DEFAULT nextval('public.areas_id_seq'::regclass);


--
-- Name: articles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles ALTER COLUMN id SET DEFAULT nextval('public.articles_id_seq'::regclass);


--
-- Name: attendances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendances ALTER COLUMN id SET DEFAULT nextval('public.attendances_id_seq'::regclass);


--
-- Name: career_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.career_applications ALTER COLUMN id SET DEFAULT nextval('public.career_applications_id_seq'::regclass);


--
-- Name: consignment_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consignment_items ALTER COLUMN id SET DEFAULT nextval('public.consignment_items_id_seq'::regclass);


--
-- Name: consignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consignments ALTER COLUMN id SET DEFAULT nextval('public.consignments_id_seq'::regclass);


--
-- Name: content_creators id_contentcreator; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_creators ALTER COLUMN id_contentcreator SET DEFAULT nextval('public.content_creators_id_contentcreator_seq'::regclass);


--
-- Name: customers id_pelanggan; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers ALTER COLUMN id_pelanggan SET DEFAULT nextval('public.customers_id_pelanggan_seq'::regclass);


--
-- Name: expenses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses ALTER COLUMN id SET DEFAULT nextval('public.expenses_id_seq'::regclass);


--
-- Name: failed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.failed_jobs ALTER COLUMN id SET DEFAULT nextval('public.failed_jobs_id_seq'::regclass);


--
-- Name: fragrance_details id_fd; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fragrance_details ALTER COLUMN id_fd SET DEFAULT nextval('public.fragrance_details_id_fd_seq'::regclass);


--
-- Name: global_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.global_settings ALTER COLUMN id SET DEFAULT nextval('public.global_settings_id_seq'::regclass);


--
-- Name: hpp_calculation_items id_hpp_item; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hpp_calculation_items ALTER COLUMN id_hpp_item SET DEFAULT nextval('public.hpp_calculation_items_id_hpp_item_seq'::regclass);


--
-- Name: hpp_calculations id_hpp; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hpp_calculations ALTER COLUMN id_hpp SET DEFAULT nextval('public.hpp_calculations_id_hpp_seq'::regclass);


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: landing_page_contents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page_contents ALTER COLUMN id SET DEFAULT nextval('public.landing_page_contents_id_seq'::regclass);


--
-- Name: marketing_bonus_adjustments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_bonus_adjustments ALTER COLUMN id SET DEFAULT nextval('public.marketing_bonus_adjustments_id_seq'::regclass);


--
-- Name: marketing_locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_locations ALTER COLUMN id SET DEFAULT nextval('public.marketing_locations_id_seq'::regclass);


--
-- Name: marketing_notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_notifications ALTER COLUMN id SET DEFAULT nextval('public.marketing_notifications_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: mobile_access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.mobile_access_tokens_id_seq'::regclass);


--
-- Name: offline_sales id_penjualan_offline; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_sales ALTER COLUMN id_penjualan_offline SET DEFAULT nextval('public.offline_sales_id_penjualan_offline_seq'::regclass);


--
-- Name: online_sale_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_sale_items ALTER COLUMN id SET DEFAULT nextval('public.online_sale_items_id_seq'::regclass);


--
-- Name: online_sales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_sales ALTER COLUMN id SET DEFAULT nextval('public.online_sales_id_seq'::regclass);


--
-- Name: permission_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permission_roles ALTER COLUMN id SET DEFAULT nextval('public.permission_roles_id_seq'::regclass);


--
-- Name: product_fragrance_details id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_fragrance_details ALTER COLUMN id SET DEFAULT nextval('public.product_fragrance_details_id_seq'::regclass);


--
-- Name: product_images id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_images ALTER COLUMN id SET DEFAULT nextval('public.product_images_id_seq'::regclass);


--
-- Name: product_onhands id_product_onhand; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_onhands ALTER COLUMN id_product_onhand SET DEFAULT nextval('public.product_onhands_id_product_onhand_seq'::regclass);


--
-- Name: products id_product; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products ALTER COLUMN id_product SET DEFAULT nextval('public.products_id_product_seq'::regclass);


--
-- Name: promos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promos ALTER COLUMN id SET DEFAULT nextval('public.promos_id_seq'::regclass);


--
-- Name: raw_materials id_rm; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raw_materials ALTER COLUMN id_rm SET DEFAULT nextval('public.raw_materials_id_rm_seq'::regclass);


--
-- Name: sales_targets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_targets ALTER COLUMN id SET DEFAULT nextval('public.sales_targets_id_seq'::regclass);


--
-- Name: seo_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seo_settings ALTER COLUMN id SET DEFAULT nextval('public.seo_settings_id_seq'::regclass);


--
-- Name: store_user_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store_user_assignments ALTER COLUMN id SET DEFAULT nextval('public.store_user_assignments_id_seq'::regclass);


--
-- Name: stores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stores ALTER COLUMN id SET DEFAULT nextval('public.stores_id_seq'::regclass);


--
-- Name: users id_user; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id_user SET DEFAULT nextval('public.users_id_user_seq'::regclass);


--
-- Name: account_payables account_payables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_payables
    ADD CONSTRAINT account_payables_pkey PRIMARY KEY (id);


--
-- Name: account_receivables account_receivables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_receivables
    ADD CONSTRAINT account_receivables_pkey PRIMARY KEY (id);


--
-- Name: areas areas_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_name_unique UNIQUE (name);


--
-- Name: areas areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_pkey PRIMARY KEY (id);


--
-- Name: articles articles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (id);


--
-- Name: articles articles_slug_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_slug_unique UNIQUE (slug);


--
-- Name: attendances attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_pkey PRIMARY KEY (id);


--
-- Name: attendances attendances_user_id_attendance_date_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_user_id_attendance_date_unique UNIQUE (user_id, attendance_date);


--
-- Name: cache_locks cache_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cache_locks
    ADD CONSTRAINT cache_locks_pkey PRIMARY KEY (key);


--
-- Name: cache cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cache
    ADD CONSTRAINT cache_pkey PRIMARY KEY (key);


--
-- Name: career_applications career_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.career_applications
    ADD CONSTRAINT career_applications_pkey PRIMARY KEY (id);


--
-- Name: consignment_items consignment_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consignment_items
    ADD CONSTRAINT consignment_items_pkey PRIMARY KEY (id);


--
-- Name: consignments consignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consignments
    ADD CONSTRAINT consignments_pkey PRIMARY KEY (id);


--
-- Name: content_creators content_creators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_creators
    ADD CONSTRAINT content_creators_pkey PRIMARY KEY (id_contentcreator);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id_pelanggan);


--
-- Name: customers customers_store_id_no_telp_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_store_id_no_telp_unique UNIQUE (store_id, no_telp);


--
-- Name: expenses expenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_pkey PRIMARY KEY (id);


--
-- Name: failed_jobs failed_jobs_uuid_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.failed_jobs
    ADD CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid);


--
-- Name: fragrance_details fragrance_details_detail_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fragrance_details
    ADD CONSTRAINT fragrance_details_detail_unique UNIQUE (detail);


--
-- Name: fragrance_details fragrance_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fragrance_details
    ADD CONSTRAINT fragrance_details_pkey PRIMARY KEY (id_fd);


--
-- Name: global_settings global_settings_key_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.global_settings
    ADD CONSTRAINT global_settings_key_unique UNIQUE (key);


--
-- Name: global_settings global_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.global_settings
    ADD CONSTRAINT global_settings_pkey PRIMARY KEY (id);


--
-- Name: hpp_calculation_items hpp_calculation_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hpp_calculation_items
    ADD CONSTRAINT hpp_calculation_items_pkey PRIMARY KEY (id_hpp_item);


--
-- Name: hpp_calculations hpp_calculations_id_product_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hpp_calculations
    ADD CONSTRAINT hpp_calculations_id_product_unique UNIQUE (id_product);


--
-- Name: hpp_calculations hpp_calculations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hpp_calculations
    ADD CONSTRAINT hpp_calculations_pkey PRIMARY KEY (id_hpp);


--
-- Name: job_batches job_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.job_batches
    ADD CONSTRAINT job_batches_pkey PRIMARY KEY (id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: landing_page_contents landing_page_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.landing_page_contents
    ADD CONSTRAINT landing_page_contents_pkey PRIMARY KEY (id);


--
-- Name: marketing_bonus_adjustments marketing_bonus_adjustments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_bonus_adjustments
    ADD CONSTRAINT marketing_bonus_adjustments_pkey PRIMARY KEY (id);


--
-- Name: marketing_locations marketing_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_locations
    ADD CONSTRAINT marketing_locations_pkey PRIMARY KEY (id);


--
-- Name: marketing_notifications marketing_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_notifications
    ADD CONSTRAINT marketing_notifications_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: mobile_access_tokens mobile_access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_access_tokens
    ADD CONSTRAINT mobile_access_tokens_pkey PRIMARY KEY (id);


--
-- Name: mobile_access_tokens mobile_access_tokens_token_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_access_tokens
    ADD CONSTRAINT mobile_access_tokens_token_unique UNIQUE (token);


--
-- Name: offline_sales offline_sales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_sales
    ADD CONSTRAINT offline_sales_pkey PRIMARY KEY (id_penjualan_offline);


--
-- Name: online_sale_items online_sale_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_sale_items
    ADD CONSTRAINT online_sale_items_pkey PRIMARY KEY (id);


--
-- Name: online_sales online_sales_order_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_sales
    ADD CONSTRAINT online_sales_order_id_unique UNIQUE (order_id);


--
-- Name: online_sales online_sales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_sales
    ADD CONSTRAINT online_sales_pkey PRIMARY KEY (id);


--
-- Name: password_reset_tokens password_reset_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_reset_tokens
    ADD CONSTRAINT password_reset_tokens_pkey PRIMARY KEY (email);


--
-- Name: permission_roles permission_roles_key_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permission_roles
    ADD CONSTRAINT permission_roles_key_unique UNIQUE (key);


--
-- Name: permission_roles permission_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permission_roles
    ADD CONSTRAINT permission_roles_pkey PRIMARY KEY (id);


--
-- Name: product_fragrance_details product_fragrance_details_id_product_id_fd_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_fragrance_details
    ADD CONSTRAINT product_fragrance_details_id_product_id_fd_unique UNIQUE (id_product, id_fd);


--
-- Name: product_fragrance_details product_fragrance_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_fragrance_details
    ADD CONSTRAINT product_fragrance_details_pkey PRIMARY KEY (id);


--
-- Name: product_images product_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_pkey PRIMARY KEY (id);


--
-- Name: product_onhands product_onhands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_onhands
    ADD CONSTRAINT product_onhands_pkey PRIMARY KEY (id_product_onhand);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id_product);


--
-- Name: products products_store_id_nama_product_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_store_id_nama_product_unique UNIQUE (store_id, nama_product);


--
-- Name: promos promos_kode_promo_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promos
    ADD CONSTRAINT promos_kode_promo_unique UNIQUE (kode_promo);


--
-- Name: promos promos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promos
    ADD CONSTRAINT promos_pkey PRIMARY KEY (id);


--
-- Name: raw_materials raw_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raw_materials
    ADD CONSTRAINT raw_materials_pkey PRIMARY KEY (id_rm);


--
-- Name: raw_materials raw_materials_store_id_nama_rm_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raw_materials
    ADD CONSTRAINT raw_materials_store_id_nama_rm_unique UNIQUE (store_id, nama_rm);


--
-- Name: sales_targets sales_targets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_targets
    ADD CONSTRAINT sales_targets_pkey PRIMARY KEY (id);


--
-- Name: sales_targets sales_targets_role_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_targets
    ADD CONSTRAINT sales_targets_role_unique UNIQUE (role);


--
-- Name: seo_settings seo_settings_page_key_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seo_settings
    ADD CONSTRAINT seo_settings_page_key_unique UNIQUE (page_key);


--
-- Name: seo_settings seo_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.seo_settings
    ADD CONSTRAINT seo_settings_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: store_user_assignments store_user_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store_user_assignments
    ADD CONSTRAINT store_user_assignments_pkey PRIMARY KEY (id);


--
-- Name: store_user_assignments store_user_assignments_user_id_store_id_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store_user_assignments
    ADD CONSTRAINT store_user_assignments_user_id_store_id_unique UNIQUE (user_id, store_id);


--
-- Name: stores stores_code_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stores
    ADD CONSTRAINT stores_code_unique UNIQUE (code);


--
-- Name: stores stores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stores
    ADD CONSTRAINT stores_pkey PRIMARY KEY (id);


--
-- Name: users users_nama_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_nama_unique UNIQUE (nama);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id_user);


--
-- Name: account_payables_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX account_payables_store_id_index ON public.account_payables USING btree (store_id);


--
-- Name: account_receivables_due_date_place_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX account_receivables_due_date_place_name_index ON public.account_receivables USING btree (due_date, place_name);


--
-- Name: account_receivables_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX account_receivables_store_id_index ON public.account_receivables USING btree (store_id);


--
-- Name: attendances_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX attendances_store_id_index ON public.attendances USING btree (store_id);


--
-- Name: cache_expiration_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cache_expiration_index ON public.cache USING btree (expiration);


--
-- Name: cache_locks_expiration_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cache_locks_expiration_index ON public.cache_locks USING btree (expiration);


--
-- Name: consignment_items_product_onhand_id_status_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX consignment_items_product_onhand_id_status_index ON public.consignment_items USING btree (product_onhand_id, status);


--
-- Name: consignments_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX consignments_store_id_index ON public.consignments USING btree (store_id);


--
-- Name: consignments_user_id_consignment_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX consignments_user_id_consignment_date_index ON public.consignments USING btree (user_id, consignment_date);


--
-- Name: customers_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX customers_store_id_index ON public.customers USING btree (store_id);


--
-- Name: expenses_category_expense_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX expenses_category_expense_date_index ON public.expenses USING btree (category, expense_date);


--
-- Name: expenses_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX expenses_store_id_index ON public.expenses USING btree (store_id);


--
-- Name: hpp_calculations_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX hpp_calculations_store_id_index ON public.hpp_calculations USING btree (store_id);


--
-- Name: jobs_queue_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX jobs_queue_index ON public.jobs USING btree (queue);


--
-- Name: landing_page_contents_section_name_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX landing_page_contents_section_name_index ON public.landing_page_contents USING btree (section_name);


--
-- Name: landing_page_contents_section_name_is_active_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX landing_page_contents_section_name_is_active_index ON public.landing_page_contents USING btree (section_name, is_active);


--
-- Name: marketing_locations_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketing_locations_store_id_index ON public.marketing_locations USING btree (store_id);


--
-- Name: marketing_locations_user_id_recorded_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketing_locations_user_id_recorded_at_index ON public.marketing_locations USING btree (user_id, recorded_at);


--
-- Name: marketing_notifications_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketing_notifications_store_id_index ON public.marketing_notifications USING btree (store_id);


--
-- Name: mobile_access_tokens_user_id_expires_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX mobile_access_tokens_user_id_expires_at_index ON public.mobile_access_tokens USING btree (user_id, expires_at);


--
-- Name: offline_sales_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX offline_sales_store_id_index ON public.offline_sales USING btree (store_id);


--
-- Name: offline_sales_transaction_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX offline_sales_transaction_code_index ON public.offline_sales USING btree (transaction_code);


--
-- Name: online_sale_items_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX online_sale_items_store_id_index ON public.online_sale_items USING btree (store_id);


--
-- Name: online_sales_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX online_sales_store_id_index ON public.online_sales USING btree (store_id);


--
-- Name: product_onhands_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_onhands_store_id_index ON public.product_onhands USING btree (store_id);


--
-- Name: products_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX products_store_id_index ON public.products USING btree (store_id);


--
-- Name: promos_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX promos_store_id_index ON public.promos USING btree (store_id);


--
-- Name: raw_materials_store_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX raw_materials_store_id_index ON public.raw_materials USING btree (store_id);


--
-- Name: sessions_last_activity_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sessions_last_activity_index ON public.sessions USING btree (last_activity);


--
-- Name: sessions_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sessions_user_id_index ON public.sessions USING btree (user_id);


--
-- Name: account_payables account_payables_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_payables
    ADD CONSTRAINT account_payables_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: account_receivables account_receivables_consignment_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_receivables
    ADD CONSTRAINT account_receivables_consignment_id_foreign FOREIGN KEY (consignment_id) REFERENCES public.consignments(id) ON DELETE SET NULL;


--
-- Name: account_receivables account_receivables_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_receivables
    ADD CONSTRAINT account_receivables_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: attendances attendances_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: attendances attendances_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id_user) ON DELETE CASCADE;


--
-- Name: consignment_items consignment_items_consignment_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consignment_items
    ADD CONSTRAINT consignment_items_consignment_id_foreign FOREIGN KEY (consignment_id) REFERENCES public.consignments(id) ON DELETE CASCADE;


--
-- Name: consignment_items consignment_items_product_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consignment_items
    ADD CONSTRAINT consignment_items_product_id_foreign FOREIGN KEY (product_id) REFERENCES public.products(id_product) ON DELETE CASCADE;


--
-- Name: consignment_items consignment_items_product_onhand_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consignment_items
    ADD CONSTRAINT consignment_items_product_onhand_id_foreign FOREIGN KEY (product_onhand_id) REFERENCES public.product_onhands(id_product_onhand) ON DELETE CASCADE;


--
-- Name: consignments consignments_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consignments
    ADD CONSTRAINT consignments_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: consignments consignments_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consignments
    ADD CONSTRAINT consignments_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id_user) ON DELETE CASCADE;


--
-- Name: customers customers_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: expenses expenses_created_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_created_by_foreign FOREIGN KEY (created_by) REFERENCES public.users(id_user) ON DELETE SET NULL;


--
-- Name: expenses expenses_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: hpp_calculation_items hpp_calculation_items_id_hpp_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hpp_calculation_items
    ADD CONSTRAINT hpp_calculation_items_id_hpp_foreign FOREIGN KEY (id_hpp) REFERENCES public.hpp_calculations(id_hpp) ON DELETE CASCADE;


--
-- Name: hpp_calculation_items hpp_calculation_items_id_rm_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hpp_calculation_items
    ADD CONSTRAINT hpp_calculation_items_id_rm_foreign FOREIGN KEY (id_rm) REFERENCES public.raw_materials(id_rm) ON DELETE CASCADE;


--
-- Name: hpp_calculations hpp_calculations_id_product_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hpp_calculations
    ADD CONSTRAINT hpp_calculations_id_product_foreign FOREIGN KEY (id_product) REFERENCES public.products(id_product) ON DELETE CASCADE;


--
-- Name: hpp_calculations hpp_calculations_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hpp_calculations
    ADD CONSTRAINT hpp_calculations_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: marketing_bonus_adjustments marketing_bonus_adjustments_created_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_bonus_adjustments
    ADD CONSTRAINT marketing_bonus_adjustments_created_by_foreign FOREIGN KEY (created_by) REFERENCES public.users(id_user) ON DELETE SET NULL;


--
-- Name: marketing_bonus_adjustments marketing_bonus_adjustments_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_bonus_adjustments
    ADD CONSTRAINT marketing_bonus_adjustments_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id_user) ON DELETE CASCADE;


--
-- Name: marketing_locations marketing_locations_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_locations
    ADD CONSTRAINT marketing_locations_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: marketing_locations marketing_locations_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_locations
    ADD CONSTRAINT marketing_locations_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id_user) ON DELETE CASCADE;


--
-- Name: marketing_notifications marketing_notifications_created_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_notifications
    ADD CONSTRAINT marketing_notifications_created_by_foreign FOREIGN KEY (created_by) REFERENCES public.users(id_user) ON DELETE SET NULL;


--
-- Name: marketing_notifications marketing_notifications_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_notifications
    ADD CONSTRAINT marketing_notifications_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: mobile_access_tokens mobile_access_tokens_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_access_tokens
    ADD CONSTRAINT mobile_access_tokens_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id_user) ON DELETE CASCADE;


--
-- Name: offline_sales offline_sales_approved_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_sales
    ADD CONSTRAINT offline_sales_approved_by_foreign FOREIGN KEY (approved_by) REFERENCES public.users(id_user) ON DELETE SET NULL;


--
-- Name: offline_sales offline_sales_id_pelanggan_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_sales
    ADD CONSTRAINT offline_sales_id_pelanggan_foreign FOREIGN KEY (id_pelanggan) REFERENCES public.customers(id_pelanggan) ON DELETE SET NULL;


--
-- Name: offline_sales offline_sales_id_product_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_sales
    ADD CONSTRAINT offline_sales_id_product_foreign FOREIGN KEY (id_product) REFERENCES public.products(id_product) ON DELETE SET NULL;


--
-- Name: offline_sales offline_sales_id_product_onhand_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_sales
    ADD CONSTRAINT offline_sales_id_product_onhand_foreign FOREIGN KEY (id_product_onhand) REFERENCES public.product_onhands(id_product_onhand) ON DELETE SET NULL;


--
-- Name: offline_sales offline_sales_id_user_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_sales
    ADD CONSTRAINT offline_sales_id_user_foreign FOREIGN KEY (id_user) REFERENCES public.users(id_user) ON DELETE CASCADE;


--
-- Name: offline_sales offline_sales_promo_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_sales
    ADD CONSTRAINT offline_sales_promo_id_foreign FOREIGN KEY (promo_id) REFERENCES public.promos(id) ON DELETE SET NULL;


--
-- Name: offline_sales offline_sales_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offline_sales
    ADD CONSTRAINT offline_sales_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: online_sale_items online_sale_items_online_sale_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_sale_items
    ADD CONSTRAINT online_sale_items_online_sale_id_foreign FOREIGN KEY (online_sale_id) REFERENCES public.online_sales(id) ON DELETE CASCADE;


--
-- Name: online_sale_items online_sale_items_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_sale_items
    ADD CONSTRAINT online_sale_items_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: online_sales online_sales_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_sales
    ADD CONSTRAINT online_sales_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: product_fragrance_details product_fragrance_details_id_fd_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_fragrance_details
    ADD CONSTRAINT product_fragrance_details_id_fd_foreign FOREIGN KEY (id_fd) REFERENCES public.fragrance_details(id_fd) ON DELETE CASCADE;


--
-- Name: product_fragrance_details product_fragrance_details_id_product_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_fragrance_details
    ADD CONSTRAINT product_fragrance_details_id_product_foreign FOREIGN KEY (id_product) REFERENCES public.products(id_product) ON DELETE CASCADE;


--
-- Name: product_images product_images_product_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_product_id_foreign FOREIGN KEY (product_id) REFERENCES public.products(id_product) ON DELETE CASCADE;


--
-- Name: product_onhands product_onhands_approved_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_onhands
    ADD CONSTRAINT product_onhands_approved_by_foreign FOREIGN KEY (approved_by) REFERENCES public.users(id_user) ON DELETE SET NULL;


--
-- Name: product_onhands product_onhands_id_product_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_onhands
    ADD CONSTRAINT product_onhands_id_product_foreign FOREIGN KEY (id_product) REFERENCES public.products(id_product) ON DELETE CASCADE;


--
-- Name: product_onhands product_onhands_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_onhands
    ADD CONSTRAINT product_onhands_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: product_onhands product_onhands_take_approved_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_onhands
    ADD CONSTRAINT product_onhands_take_approved_by_foreign FOREIGN KEY (take_approved_by) REFERENCES public.users(id_user) ON DELETE SET NULL;


--
-- Name: product_onhands product_onhands_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_onhands
    ADD CONSTRAINT product_onhands_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id_user) ON DELETE CASCADE;


--
-- Name: products products_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: promos promos_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.promos
    ADD CONSTRAINT promos_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: raw_materials raw_materials_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raw_materials
    ADD CONSTRAINT raw_materials_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: store_user_assignments store_user_assignments_store_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store_user_assignments
    ADD CONSTRAINT store_user_assignments_store_id_foreign FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;


--
-- Name: store_user_assignments store_user_assignments_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store_user_assignments
    ADD CONSTRAINT store_user_assignments_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id_user) ON DELETE CASCADE;


--
-- Name: users users_permission_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_permission_role_id_foreign FOREIGN KEY (permission_role_id) REFERENCES public.permission_roles(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

