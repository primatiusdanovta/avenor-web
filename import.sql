--
-- PostgreSQL database dump
--

\restrict efpJFID6JUHPU7eYQF7CJUeSy7TkiJp9mRRsW2MacxIRVe8XPlTPXfloXeb1sqE

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
    updated_at timestamp(0) without time zone
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
    pembelian_terakhir timestamp(0) without time zone
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
    updated_at timestamp(0) without time zone
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
    updated_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
-- Name: marketing_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.marketing_locations (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    latitude numeric(10,7) NOT NULL,
    longitude numeric(10,7) NOT NULL,
    source character varying(20) DEFAULT 'heartbeat'::character varying NOT NULL,
    recorded_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
    total_hpp numeric(15,2) DEFAULT '0'::numeric NOT NULL
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
    updated_at timestamp(0) without time zone
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
    updated_at timestamp(0) without time zone
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
    take_reviewed_at timestamp(0) without time zone
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
    educational_blocks json
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
    created_at timestamp(0) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
    harga_total numeric(15,2) DEFAULT '0'::numeric NOT NULL
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
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['superadmin'::character varying, 'admin'::character varying, 'marketing'::character varying, 'reseller'::character varying])::text[])))
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
-- Name: areas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas ALTER COLUMN id SET DEFAULT nextval('public.areas_id_seq'::regclass);


--
-- Name: attendances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendances ALTER COLUMN id SET DEFAULT nextval('public.attendances_id_seq'::regclass);


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
-- Name: marketing_locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_locations ALTER COLUMN id SET DEFAULT nextval('public.marketing_locations_id_seq'::regclass);


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


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
-- Name: product_fragrance_details id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_fragrance_details ALTER COLUMN id SET DEFAULT nextval('public.product_fragrance_details_id_seq'::regclass);


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
-- Name: users id_user; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id_user SET DEFAULT nextval('public.users_id_user_seq'::regclass);


--
-- Data for Name: account_payables; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: areas; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: attendances; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: cache; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: cache_locks; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: content_creators; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.customers (id_pelanggan, nama, no_telp, tiktok_instagram, created_at, pembelian_terakhir) VALUES (1, 'test', '012345', 'testt', '2026-03-30 05:04:00', '2026-03-30 05:04:00');


--
-- Data for Name: expenses; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: failed_jobs; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: fragrance_details; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (1, 'universal', 'Wanita', 'Aroma yang umum disukai untuk karakter feminin.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (2, 'universal', 'Pria', 'Aroma yang umum disukai untuk karakter maskulin.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (3, 'universal', 'Unisex', 'Aroma yang cocok digunakan pria maupun wanita.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (4, 'fragrance family', 'Citrus', 'Nuansa segar dari buah-buahan sitrus.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (5, 'fragrance family', 'Woody', 'Nuansa kayu yang hangat dan elegan.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (6, 'fragrance family', 'Fresh', 'Nuansa ringan, bersih, dan menyegarkan.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (7, 'fragrance family', 'Aquatic', 'Nuansa airy dan watery yang segar.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (8, 'fragrance family', 'Gourmand', 'Nuansa manis seperti dessert dan edible notes.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (9, 'fragrance family', 'Sweet', 'Nuansa manis yang dominan dan playful.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (10, 'fragrance family', 'Floral', 'Nuansa bunga yang lembut hingga mewah.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (11, 'fragrance family', 'Green/Herbal', 'Nuansa dedaunan, herbal, dan natural.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (12, 'fragrance family', 'Spicy/Aromatic', 'Nuansa rempah dan aromatic yang tegas.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (13, 'fragrance family', 'Fougere', 'Nuansa klasik aromatic dengan herbal dan woody.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (14, 'fragrance family', 'Chypre', 'Nuansa elegan dengan balance citrus, moss, dan woody.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (15, 'activities', 'Versatile', 'Cocok dipakai di banyak suasana dan waktu.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (16, 'activities', 'Formal & Elegan', 'Cocok untuk acara resmi dan kesan sophisticated.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (17, 'activities', 'Hangout/Daily', 'Nyaman untuk aktivitas santai dan harian.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (18, 'activities', 'Sensual/Intens', 'Karakter aroma yang lebih bold dan memikat.', '2026-03-30 03:48:01');
INSERT INTO public.fragrance_details (id_fd, jenis, detail, deskripsi, created_at) VALUES (19, 'activities', 'Sports', 'Cocok untuk aktivitas aktif dan suasana energik.', '2026-03-30 03:48:01');


--
-- Data for Name: global_settings; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.global_settings (id, key, value, created_at, updated_at) VALUES (1, 'master_social_hub', '{"tiktok_url":"https:\/\/www.tiktok.com\/@avenorperfume","instagram_url":"https:\/\/www.instagram.com\/avenorperfume_\/","facebook_url":"https:\/\/www.facebook.com\/AvenorPerfume","whatsapp_url":null,"tokopedia_url":"https:\/\/tk.tokopedia.com\/ZSHYbroDF\/","tiktok_shop_url":null,"hero_video_path":"landing\/hero-videos\/b1bb281c-4c19-4a0b-86ab-3804c0a550fe.mp4","hero_video_mime":"video\/mp4","cards":{"tiktok":{"eyebrow":"TikTok","title":"Review Highlights","description":"Short-form fragrance impressions, reactions, and launch moments."},"instagram":{"eyebrow":"Instagram","title":"Aesthetic Grid","description":"Editorial visuals, rituals, and product stories in a curated gallery."},"whatsapp":{"eyebrow":"WhatsApp","title":"Consult with Our Scent Expert","description":"Start a direct conversation and get guided toward the right scent."}}}', '2026-03-31 22:50:50', '2026-04-01 00:26:46');


--
-- Data for Name: hpp_calculation_items; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: hpp_calculations; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: job_batches; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: landing_page_contents; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (1, 'hero', 'Avenor Nocturne', 'A fragrance study in gold, smoke, and midnight florals. Crafted as a modern luxury ritual for the senses.', NULL, true, '{"badge":"Maison Avenor","eyebrow":"Modern Dark Luxury","cta_label":"Discover The Notes","cta_href":"#notes-journey","secondary_label":"View Ingredients","secondary_href":"#ingredients-bento"}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO public.landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (2, 'story', 'A fragrance revealed in three luminous movements.', 'From the first sparkling release to the warm resinous trail, each accord is designed to unfold like a private gallery experience.', NULL, true, '{"kicker":"Narrative Scroll"}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO public.landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (3, 'top_notes', 'Top Notes', 'Bergamot zest, pink pepper, and saffron shimmer with a cold metallic glow before melting into skin.', NULL, true, '{"order":1,"short_label":"Top","accent":"#d4af37"}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO public.landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (4, 'heart_notes', 'Heart Notes', 'Dark rose and jasmine sambac bloom at the center, softened by incense smoke and velvet woods.', NULL, true, '{"order":2,"short_label":"Heart","accent":"#b7922f"}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO public.landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (5, 'base_notes', 'Base Notes', 'Amber, sandalwood, and patchouli settle into a long, tactile finish with warm leather depth.', NULL, true, '{"order":3,"short_label":"Base","accent":"#8d6a1f"}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO public.landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (6, 'ingredients_intro', 'Ingredient Bento', 'A precise composition of rare textures, sparkling spices, and lingering woods.', NULL, true, '{"kicker":"Tap to Reveal"}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO public.landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (7, 'ingredient', 'Saffron Thread', 'Adds a radiant, suede-like heat and metallic glow in the opening accord.', NULL, true, '{"key":"ingredient-saffron-thread","icon":"spark","order":1}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO public.landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (8, 'ingredient', 'Rose Absolute', 'A deep floral heart that feels lush, nocturnal, and quietly dramatic.', NULL, true, '{"key":"ingredient-rose-absolute","icon":"bloom","order":2}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO public.landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (9, 'ingredient', 'Sandalwood', 'Brings creamy depth and a polished, skin-close finish to the dry down.', NULL, true, '{"key":"ingredient-sandalwood","icon":"wood","order":3}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO public.landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (10, 'ingredient', 'Pink Pepper', 'Lifts the composition with crisp sparkle and subtle contemporary spice.', NULL, true, '{"key":"ingredient-pink-pepper","icon":"pepper","order":4}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO public.landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (11, 'ingredient', 'Amber Resin', 'Creates an enveloping glow that lingers with warmth and golden density.', NULL, true, '{"key":"ingredient-amber-resin","icon":"amber","order":5}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');
INSERT INTO public.landing_page_contents (id, section_name, title, description, image_path, is_active, meta_data, created_at, updated_at) VALUES (12, 'ingredient', 'Incense Smoke', 'Adds a dark ceremonial trail that turns the scent into an atmosphere.', NULL, true, '{"key":"ingredient-incense-smoke","icon":"smoke","order":6}', '2026-03-31 20:31:48', '2026-03-31 20:31:48');


--
-- Data for Name: marketing_locations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (1, 3, -6.3226313, 106.9609515, 'heartbeat', '2026-03-30 03:52:57');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (2, 3, -6.3226805, 106.9609328, 'heartbeat', '2026-03-30 08:02:48');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (3, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 09:43:20');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (4, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 09:48:22');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (5, 3, -6.3226347, 106.9610332, 'heartbeat', '2026-03-30 09:51:59');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (6, 3, -6.3226617, 106.9610690, 'heartbeat', '2026-03-30 09:57:13');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (7, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 10:02:41');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (8, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 10:02:47');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (9, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 10:07:36');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (10, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 10:08:02');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (11, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 10:11:32');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (12, 3, -6.3226317, 106.9609576, 'heartbeat', '2026-03-30 10:30:25');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (13, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-30 10:43:58');
INSERT INTO public.marketing_locations (id, user_id, latitude, longitude, source, recorded_at) VALUES (14, 3, -6.3226351, 106.9610410, 'heartbeat', '2026-03-31 18:05:07');


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.migrations (id, migration, batch) VALUES (1, '0001_01_01_000000_create_users_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (2, '0001_01_01_000001_create_cache_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (3, '0001_01_01_000002_create_jobs_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (4, '2026_03_24_000003_create_areas_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (5, '2026_03_24_000004_create_attendances_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (6, '2026_03_24_000005_update_attendances_for_location_tracking', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (7, '2026_03_24_000006_create_marketing_locations_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (8, '2026_03_24_000007_create_products_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (9, '2026_03_24_000008_create_promos_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (10, '2026_03_24_000009_create_product_onhands_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (11, '2026_03_24_000010_create_offline_sales_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (12, '2026_03_24_000011_add_id_product_onhand_to_offline_sales_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (13, '2026_03_24_000012_add_take_approval_to_product_onhands_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (14, '2026_03_24_000013_create_raw_materials_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (15, '2026_03_24_000014_add_satuan_to_raw_materials_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (16, '2026_03_24_000015_update_raw_material_totals', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (17, '2026_03_24_000016_create_hpp_calculations_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (18, '2026_03_24_000017_create_hpp_calculation_items_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (19, '2026_03_28_000018_create_customers_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (20, '2026_03_28_000019_add_id_pelanggan_to_offline_sales_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (21, '2026_03_28_000020_add_transaction_code_to_offline_sales_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (22, '2026_03_28_000021_update_raw_material_precision_and_add_hpp_item_stock', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (23, '2026_03_28_000022_create_content_creators_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (24, '2026_03_30_000023_create_sales_targets_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (25, '2026_03_30_000024_create_online_sales_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (26, '2026_03_30_000025_create_online_sale_items_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (27, '2026_03_30_000026_create_fragrance_details_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (28, '2026_03_30_000027_add_description_to_products_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (29, '2026_03_30_000028_create_product_fragrance_details_table', 1);
INSERT INTO public.migrations (id, migration, batch) VALUES (30, '2026_03_31_000021_add_total_hpp_to_offline_sales_table', 2);
INSERT INTO public.migrations (id, migration, batch) VALUES (31, '2026_03_31_000022_fix_sales_targets_id_auto_increment', 2);
INSERT INTO public.migrations (id, migration, batch) VALUES (32, '2026_03_31_000023_create_expenses_table', 2);
INSERT INTO public.migrations (id, migration, batch) VALUES (33, '2026_04_01_000024_add_require_return_before_checkout_to_users_table', 2);
INSERT INTO public.migrations (id, migration, batch) VALUES (34, '2026_04_01_000025_create_account_payables_table', 2);
INSERT INTO public.migrations (id, migration, batch) VALUES (35, '2026_04_01_000026_create_landing_page_contents_table', 3);
INSERT INTO public.migrations (id, migration, batch) VALUES (36, '2026_04_01_000027_create_seo_settings_table', 3);
INSERT INTO public.migrations (id, migration, batch) VALUES (37, '2026_04_01_000028_add_landing_fields_to_products_table', 4);
INSERT INTO public.migrations (id, migration, batch) VALUES (38, '2026_04_01_000029_add_faq_and_educational_blocks_to_products_table', 4);
INSERT INTO public.migrations (id, migration, batch) VALUES (39, '2026_04_01_000030_create_global_settings_table', 4);


--
-- Data for Name: offline_sales; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.offline_sales (id_penjualan_offline, id_user, id_product, promo_id, nama, nama_product, quantity, harga, kode_promo, promo, bukti_pembelian, approval_status, approved_by, approved_at, created_at, id_product_onhand, id_pelanggan, transaction_code, total_hpp) VALUES (1043, 1, 3, NULL, 'superadmin', 'Azalea', 2, 150000.00, NULL, NULL, 'offline-sales/5b0bJhNcj1oxQYK5slolp6hkRMLedFtj6On5fwVY.png', 'disetujui', 1, '2026-03-30 05:04:00', '2026-03-30 05:04:00', NULL, 1, 'TRX-20260330050450-MNF2P68U', 0.00);


--
-- Data for Name: online_sale_items; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (1, 1, NULL, 'Zest by Avenor Perfume - Extrait de perfume - 50ml', 'Zest by Avenor Perfume - Extrait de perfume - 50ml', 1, 68663.00, '2026-03-17 10:58:19', '2026-03-30 05:51:46');
INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (2, 2, 3, 'Azalea by Avenor Perfume - Extrait de parfum - 50ml', 'Azalea', 1, 40423.00, '2026-03-14 12:19:59', '2026-03-30 05:51:46');
INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (3, 3, 2, 'Sevon by Avenor Perfume  - Extrait de parfum - Parfum tahan lama untuk Laki-Laki Pria - Wanginya Maskulin - 50ml', 'Sevon', 1, 44256.00, '2026-03-16 08:31:34', '2026-03-30 05:51:46');
INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (4, 4, 1, 'Solair by Avenor Perfume  - Extrait de parfum - 50ml', 'Solair', 1, 45032.00, '2026-03-11 10:53:07', '2026-03-30 05:51:46');
INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (5, 4, 3, 'Azalea by Avenor Perfume - Extrait de parfum - 50ml', 'Azalea', 1, 45032.00, '2026-03-11 10:53:07', '2026-03-30 05:51:46');
INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (6, 5, NULL, 'Honeydew by Avenor Perfume - Extrait de perfume - 50ml', 'Honeydew by Avenor Perfume - Extrait de perfume - 50ml', 1, 46537.00, '2026-03-14 18:35:35', '2026-03-30 05:51:46');
INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (7, 5, 1, 'Solair by Avenor Perfume  - Extrait de parfum - 50ml', 'Solair', 1, 46537.00, '2026-03-14 18:35:35', '2026-03-30 05:51:46');
INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (8, 6, 1, 'Solair by Avenor Perfume  - Extrait de parfum - 50ml', 'Solair', 1, 43738.00, '2026-03-12 08:57:40', '2026-03-30 05:51:46');
INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (9, 7, NULL, 'Honeydew by Avenor Perfume - Extrait de perfume - 50ml', 'Honeydew by Avenor Perfume - Extrait de perfume - 50ml', 1, 46745.33, '2026-03-13 10:16:48', '2026-03-30 05:51:46');
INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (10, 7, NULL, 'Blossom Crème by Avenor Perfume - Extrait de perfume - 50ml - Wangi Creamy', 'Blossom Crème by Avenor Perfume - Extrait de perfume - 50ml - Wangi Creamy', 1, 46745.33, '2026-03-13 10:16:48', '2026-03-30 05:51:46');
INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (11, 7, 4, 'Athena by Avenor Perfume - Parfum untuk Wanita - Extrait de parfum - 50ml', 'Athena', 1, 46745.34, '2026-03-13 10:16:48', '2026-03-30 05:51:46');
INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (12, 8, 4, 'Athena by Avenor Perfume - Parfum untuk Wanita - Extrait de parfum - 50ml', 'Athena', 2, 69881.00, '2026-03-09 10:26:55', '2026-03-30 05:51:46');
INSERT INTO public.online_sale_items (id, online_sale_id, id_product, raw_product_name, nama_product, quantity, harga, created_at, updated_at) VALUES (13, 9, 1, 'Solair by Avenor Perfume  - Extrait de parfum - 50ml', 'Solair', 1, 46538.00, '2026-03-09 06:30:35', '2026-03-30 05:51:46');


--
-- Data for Name: online_sales; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (1, '583083275656070698', 'Selesai', 'Selesai', '', 'Banten', 'Kota Tangerang', '2026-03-17 10:58:19', 68663.00, '2026-03-17 10:58:19', '2026-03-30 05:51:46');
INSERT INTO public.online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (2, '583043939786327209', 'Selesai', 'Selesai', '', 'Jawa Barat', 'Kota Bekasi', '2026-03-14 12:19:59', 40423.00, '2026-03-14 12:19:59', '2026-03-30 05:51:46');
INSERT INTO public.online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (3, '583042456174626087', 'Selesai', 'Selesai', '', 'Jawa Timur', 'Kabupaten Bangkalan', '2026-03-16 08:31:34', 44256.00, '2026-03-16 08:31:34', '2026-03-30 05:51:46');
INSERT INTO public.online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (4, '583023183878391116', 'Selesai', 'Selesai', '', 'D.I. Yogyakarta', 'Kab. Kulon Progo', '2026-03-11 10:53:07', 90064.00, '2026-03-11 10:53:07', '2026-03-30 05:51:46');
INSERT INTO public.online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (5, '582994516850804222', 'Selesai', 'Selesai', '', 'Sulawesi Tenggara', 'Kota Kendari', '2026-03-14 18:35:35', 93074.00, '2026-03-14 18:35:35', '2026-03-30 05:51:46');
INSERT INTO public.online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (6, '582990768866886951', 'Selesai', 'Selesai', '', 'Jawa Timur', 'Kabupaten Bangkalan', '2026-03-12 08:57:40', 43738.00, '2026-03-12 08:57:40', '2026-03-30 05:51:46');
INSERT INTO public.online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (7, '582988929179551513', 'Selesai', 'Selesai', '', 'North Sumatra', 'Medan City', '2026-03-13 10:16:48', 140236.00, '2026-03-13 10:16:48', '2026-03-30 05:51:46');
INSERT INTO public.online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (8, '582988803961160993', 'Selesai', 'Selesai', '', 'Jawa Barat', 'Kota Bekasi', '2026-03-09 10:26:55', 69881.00, '2026-03-09 10:26:55', '2026-03-30 05:51:46');
INSERT INTO public.online_sales (id, order_id, order_status, order_substatus, cancelation, province, regency_city, paid_time, total_amount, created_at, updated_at) VALUES (9, '582986027112105413', 'Selesai', 'Selesai', '', 'Banten', 'Kota Tangerang', '2026-03-09 06:30:35', 46538.00, '2026-03-09 06:30:35', '2026-03-30 05:51:46');


--
-- Data for Name: password_reset_tokens; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: product_fragrance_details; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.product_fragrance_details (id, id_product, id_fd, created_at) VALUES (1, 1, 2, '2026-03-30 12:17:06');
INSERT INTO public.product_fragrance_details (id, id_product, id_fd, created_at) VALUES (2, 1, 3, '2026-03-30 12:17:06');
INSERT INTO public.product_fragrance_details (id, id_product, id_fd, created_at) VALUES (3, 1, 14, '2026-03-30 12:17:06');
INSERT INTO public.product_fragrance_details (id, id_product, id_fd, created_at) VALUES (4, 1, 4, '2026-03-30 12:17:06');
INSERT INTO public.product_fragrance_details (id, id_product, id_fd, created_at) VALUES (5, 1, 6, '2026-03-30 12:17:06');
INSERT INTO public.product_fragrance_details (id, id_product, id_fd, created_at) VALUES (6, 4, 17, '2026-03-31 23:14:27');
INSERT INTO public.product_fragrance_details (id, id_product, id_fd, created_at) VALUES (7, 4, 6, '2026-03-31 23:14:27');
INSERT INTO public.product_fragrance_details (id, id_product, id_fd, created_at) VALUES (8, 4, 11, '2026-03-31 23:14:27');
INSERT INTO public.product_fragrance_details (id, id_product, id_fd, created_at) VALUES (9, 4, 12, '2026-03-31 23:14:27');


--
-- Data for Name: product_onhands; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.products (id_product, nama_product, harga, harga_modal, stock, gambar, created_at, deskripsi, landing_page_active, seo_title, seo_description, canonical_url, top_notes_text, heart_notes_text, base_notes_text, education_content, faq_data, educational_blocks) VALUES (2, 'Sevon', 75000.00, 0.00, 0, NULL, '2026-03-30 03:48:01', 'Woody aromatic perfume dengan karakter elegan.', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.products (id_product, nama_product, harga, harga_modal, stock, gambar, created_at, deskripsi, landing_page_active, seo_title, seo_description, canonical_url, top_notes_text, heart_notes_text, base_notes_text, education_content, faq_data, educational_blocks) VALUES (3, 'Azalea', 75000.00, 0.00, 0, NULL, '2026-03-30 03:48:01', 'Floral sweet perfume dengan kesan lembut.', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.products (id_product, nama_product, harga, harga_modal, stock, gambar, created_at, deskripsi, landing_page_active, seo_title, seo_description, canonical_url, top_notes_text, heart_notes_text, base_notes_text, education_content, faq_data, educational_blocks) VALUES (4, 'Athena', 75000.00, 0.00, 0, 'products/nSn3G2y0AhMVMtzAqDh4ARneCtvb6cxDjCEwGnZ1.png', '2026-03-30 03:48:01', 'Fresh floral perfume untuk kesan modern. Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.Fresh floral perfume untuk kesan modern.', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.products (id_product, nama_product, harga, harga_modal, stock, gambar, created_at, deskripsi, landing_page_active, seo_title, seo_description, canonical_url, top_notes_text, heart_notes_text, base_notes_text, education_content, faq_data, educational_blocks) VALUES (1, 'Solair', 75000.00, 0.00, 0, NULL, '2026-03-30 03:48:01', 'Fresh citrus perfume untuk pemakaian harian.', true, NULL, NULL, NULL, NULL, NULL, NULL, '{"title":"Customer Education","body":null,"tips":[]}', '[]', '{"title":"Customer Education","body":null,"tips":[]}');


--
-- Data for Name: promos; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: raw_materials; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: sales_targets; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.sales_targets (id, role, daily_target_qty, daily_bonus, weekly_target_qty, weekly_bonus, monthly_target_qty, monthly_bonus, created_at, updated_at) VALUES (2, 'reseller', 0, 0.00, 0, 0.00, 0, 0.00, '2026-03-30 03:48:01', '2026-03-30 03:48:01');
INSERT INTO public.sales_targets (id, role, daily_target_qty, daily_bonus, weekly_target_qty, weekly_bonus, monthly_target_qty, monthly_bonus, created_at, updated_at) VALUES (1, 'marketing', 4, 0.00, 24, 350000.00, 100, 1500000.00, '2026-03-30 03:48:01', '2026-03-30 03:51:17');


--
-- Data for Name: seo_settings; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.seo_settings (id, page_key, title, meta_description, meta_keywords, canonical_url, og_title, og_description, og_image, robots, schema_json, is_active, created_at, updated_at) VALUES (1, 'landing', 'Avenor Perfume | Luxury Fragrance Experience', 'Discover Avenor Perfume through a modern dark luxury landing page featuring scent stages, ingredients, and a refined fragrance narrative.', 'avenor perfume, parfum mewah, luxury perfume, fragrance notes, parfum premium', NULL, 'Avenor Perfume | Luxury Fragrance Experience', 'A modern dark luxury fragrance discovery experience with immersive notes and ingredient storytelling.', NULL, 'index,follow', '{
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "Avenor Perfume",
    "description": "Luxury fragrance experience by Avenor Perfume."
}', true, '2026-03-31 20:31:48', '2026-03-31 20:31:48');


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('Qjec2JZpCnKAIbROXRLIfHrFRoTstSmvNywdBpvm', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.7632.6 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoibExLcm9iNXd1MmFVcXlPMFNQQTdSYW9Da2UxdXFrU3dDNGJqQXpFbCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAxMi9tYXN0ZXItaGVyby12aWRlbz92PTJkZWUyYjgyZjZkNWEwZjljYjZhNDUwMDU1YjFhM2MyIjtzOjU6InJvdXRlIjtzOjMzOiJnbG9iYWwtc2V0dGluZ3MubWFzdGVyLWhlcm8tdmlkZW8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1775042016);
INSERT INTO public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('UlHS4wUgmb7Puo8pHJc2tEhMrRhlfGTtoTLK6YbK', NULL, '127.0.0.1', 'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Mobile Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoibzBqc2VzRGQxM3N3bm40YnAxZnJKWGlSQVp4MkNONFdodnZmVVdDNyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAxMi9tYXN0ZXItaGVyby12aWRlbz92PTJkZWUyYjgyZjZkNWEwZjljYjZhNDUwMDU1YjFhM2MyIjtzOjU6InJvdXRlIjtzOjMzOiJnbG9iYWwtc2V0dGluZ3MubWFzdGVyLWhlcm8tdmlkZW8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1775042034);
INSERT INTO public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('ovpqqtun4UhI77GLUiiOmBQfj4cwoOjaKLfJDqWA', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.7632.6 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiVDl2aXlWRVpnR1pPdmMwT2wwNDNrRmNWdVZhRTB4V1d0TFJJY1ExTyI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAxMi9tYXN0ZXItaGVyby12aWRlbz92PTJkZWUyYjgyZjZkNWEwZjljYjZhNDUwMDU1YjFhM2MyIjtzOjU6InJvdXRlIjtzOjMzOiJnbG9iYWwtc2V0dGluZ3MubWFzdGVyLWhlcm8tdmlkZW8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1775042098);
INSERT INTO public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('FnZsrOqtn9txzeGgKJtNuBBqKStR5rumrmvKZ0su', NULL, '127.0.0.1', 'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Mobile Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiUTFHTVA4VFZWc2Z1T2N5NEhGY1ROY3dtMXhUT3MxZUpYSldHUHZUNiI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAxMi9tYXN0ZXItaGVyby12aWRlbz92PTJkZWUyYjgyZjZkNWEwZjljYjZhNDUwMDU1YjFhM2MyIjtzOjU6InJvdXRlIjtzOjMzOiJnbG9iYWwtc2V0dGluZ3MubWFzdGVyLWhlcm8tdmlkZW8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1775042106);
INSERT INTO public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('XjcxuySqguWrXlr7LI3eK9ktL92UTtrQ8Jd7mquq', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.7632.6 Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiRDJhSDc4Q3B1cjZ3d2RLS0dBSWJsRVN6UzFCUTRZUUU2QkljQ3BLeSI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAxMi9tYXN0ZXItaGVyby12aWRlbz92PTJkZWUyYjgyZjZkNWEwZjljYjZhNDUwMDU1YjFhM2MyIjtzOjU6InJvdXRlIjtzOjMzOiJnbG9iYWwtc2V0dGluZ3MubWFzdGVyLWhlcm8tdmlkZW8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1775042168);
INSERT INTO public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('WLGDnp4tvk6Rj82SqYDnaRcCUTGD1yZZDz2EeGrl', NULL, '127.0.0.1', 'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.7632.6 Mobile Safari/537.36', 'YTozOntzOjY6Il90b2tlbiI7czo0MDoiWDR3cU1aQlhSMnNWNXg4aFEwQ21RRjlweTZlZmJkeUtXdFdBZTEwOCI7czo5OiJfcHJldmlvdXMiO2E6Mjp7czozOiJ1cmwiO3M6NzQ6Imh0dHA6Ly8xMjcuMC4wLjE6ODAxMi9tYXN0ZXItaGVyby12aWRlbz92PTJkZWUyYjgyZjZkNWEwZjljYjZhNDUwMDU1YjFhM2MyIjtzOjU6InJvdXRlIjtzOjMzOiJnbG9iYWwtc2V0dGluZ3MubWFzdGVyLWhlcm8tdmlkZW8iO31zOjY6Il9mbGFzaCI7YToyOntzOjM6Im9sZCI7YTowOnt9czozOiJuZXciO2E6MDp7fX19', 1775042176);
INSERT INTO public.sessions (id, user_id, ip_address, user_agent, payload, last_activity) VALUES ('K2GqOL2n0eywJO8Qp7b8cdCfrsXeZLtY9HrAyBK1', 1, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36', 'YTo0OntzOjY6Il90b2tlbiI7czo0MDoiWndRcXZtSXJCdmJlSkE0NzNndlJ2ajJwU3NiREdZQ1h0cmx6NmhFTSI7czo1MDoibG9naW5fd2ViXzU5YmEzNmFkZGMyYjJmOTQwMTU4MGYwMTRjN2Y1OGVhNGUzMDk4OWQiO2k6MTtzOjk6Il9wcmV2aW91cyI7YToyOntzOjM6InVybCI7czo3NDoiaHR0cDovLzEyNy4wLjAuMTo4MDAwL21hc3Rlci1oZXJvLXZpZGVvP3Y9MmRlZTJiODJmNmQ1YTBmOWNiNmE0NTAwNTViMWEzYzIiO3M6NToicm91dGUiO3M6MzM6Imdsb2JhbC1zZXR0aW5ncy5tYXN0ZXItaGVyby12aWRlbyI7fXM6NjoiX2ZsYXNoIjthOjI6e3M6Mzoib2xkIjthOjA6e31zOjM6Im5ldyI7YTowOnt9fX0=', 1775051410);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users (id_user, nama, status, role, password, remember_token, created_at, require_return_before_checkout) VALUES (2, 'admin', 'aktif', 'admin', '$2y$12$btrQAWjikxBkLtFk0wmHd.tFbAzPa86jVP3mWR3L2IEOByBN1OU9S', NULL, '2026-03-30 03:47:59', true);
INSERT INTO public.users (id_user, nama, status, role, password, remember_token, created_at, require_return_before_checkout) VALUES (4, 'reseller', 'aktif', 'reseller', '$2y$12$0AuMbJL/hpAvlTdQi7qoTumAsFDDX4uH3L8HwSUN9Ibn3DEPrTcAe', NULL, '2026-03-30 03:48:00', true);
INSERT INTO public.users (id_user, nama, status, role, password, remember_token, created_at, require_return_before_checkout) VALUES (1, 'superadmin', 'aktif', 'superadmin', '$2y$12$qPgNe9Z4mNvXVst8jC1NC.eg0mCR04gdpKpiqix6qjgEaJuYiUzwi', '3Qwk4b56rETDWqKb5RSaswkfCDZ1XjK15y8FdCTTtlomnoNK9DnIGDvw7JRm', '2026-03-30 03:47:58', true);
INSERT INTO public.users (id_user, nama, status, role, password, remember_token, created_at, require_return_before_checkout) VALUES (3, 'marketing', 'aktif', 'marketing', '$2y$12$OrtqI5C0brMgFnALF.1Peuaib3DRQxBQjgBfW60AAFcztGA0WPS2K', 'eRrAqCM8qLxjjO02UArilhooKKpYv1DI7DKBZ2CBaseBl80w8WZuuwp9VFMo', '2026-03-30 03:48:00', false);


--
-- Name: account_payables_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.account_payables_id_seq', 1, false);


--
-- Name: areas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.areas_id_seq', 1, false);


--
-- Name: attendances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.attendances_id_seq', 1, false);


--
-- Name: content_creators_id_contentcreator_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.content_creators_id_contentcreator_seq', 1, false);


--
-- Name: customers_id_pelanggan_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.customers_id_pelanggan_seq', 1, true);


--
-- Name: expenses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.expenses_id_seq', 1, false);


--
-- Name: failed_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.failed_jobs_id_seq', 1, false);


--
-- Name: fragrance_details_id_fd_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.fragrance_details_id_fd_seq', 19, true);


--
-- Name: global_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.global_settings_id_seq', 1, true);


--
-- Name: hpp_calculation_items_id_hpp_item_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.hpp_calculation_items_id_hpp_item_seq', 1, false);


--
-- Name: hpp_calculations_id_hpp_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.hpp_calculations_id_hpp_seq', 1, false);


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.jobs_id_seq', 1, false);


--
-- Name: landing_page_contents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.landing_page_contents_id_seq', 12, true);


--
-- Name: marketing_locations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.marketing_locations_id_seq', 14, true);


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.migrations_id_seq', 39, true);


--
-- Name: offline_sales_id_penjualan_offline_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.offline_sales_id_penjualan_offline_seq', 1043, true);


--
-- Name: online_sale_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.online_sale_items_id_seq', 13, true);


--
-- Name: online_sales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.online_sales_id_seq', 9, true);


--
-- Name: product_fragrance_details_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.product_fragrance_details_id_seq', 9, true);


--
-- Name: product_onhands_id_product_onhand_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.product_onhands_id_product_onhand_seq', 1, false);


--
-- Name: products_id_product_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.products_id_product_seq', 7, true);


--
-- Name: promos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.promos_id_seq', 1, false);


--
-- Name: raw_materials_id_rm_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.raw_materials_id_rm_seq', 1, false);


--
-- Name: sales_targets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sales_targets_id_seq', 2, true);


--
-- Name: seo_settings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seo_settings_id_seq', 1, true);


--
-- Name: users_id_user_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_user_seq', 4, true);


--
-- Name: account_payables account_payables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_payables
    ADD CONSTRAINT account_payables_pkey PRIMARY KEY (id);


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
-- Name: content_creators content_creators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_creators
    ADD CONSTRAINT content_creators_pkey PRIMARY KEY (id_contentcreator);


--
-- Name: customers customers_no_telp_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_no_telp_unique UNIQUE (no_telp);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id_pelanggan);


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
-- Name: marketing_locations marketing_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_locations
    ADD CONSTRAINT marketing_locations_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


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
-- Name: product_onhands product_onhands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_onhands
    ADD CONSTRAINT product_onhands_pkey PRIMARY KEY (id_product_onhand);


--
-- Name: products products_nama_product_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_nama_product_unique UNIQUE (nama_product);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id_product);


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
-- Name: raw_materials raw_materials_nama_rm_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raw_materials
    ADD CONSTRAINT raw_materials_nama_rm_unique UNIQUE (nama_rm);


--
-- Name: raw_materials raw_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.raw_materials
    ADD CONSTRAINT raw_materials_pkey PRIMARY KEY (id_rm);


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
-- Name: cache_expiration_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cache_expiration_index ON public.cache USING btree (expiration);


--
-- Name: cache_locks_expiration_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cache_locks_expiration_index ON public.cache_locks USING btree (expiration);


--
-- Name: expenses_category_expense_date_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX expenses_category_expense_date_index ON public.expenses USING btree (category, expense_date);


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
-- Name: marketing_locations_user_id_recorded_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX marketing_locations_user_id_recorded_at_index ON public.marketing_locations USING btree (user_id, recorded_at);


--
-- Name: offline_sales_transaction_code_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX offline_sales_transaction_code_index ON public.offline_sales USING btree (transaction_code);


--
-- Name: sessions_last_activity_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sessions_last_activity_index ON public.sessions USING btree (last_activity);


--
-- Name: sessions_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sessions_user_id_index ON public.sessions USING btree (user_id);


--
-- Name: attendances attendances_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendances
    ADD CONSTRAINT attendances_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id_user) ON DELETE CASCADE;


--
-- Name: expenses expenses_created_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.expenses
    ADD CONSTRAINT expenses_created_by_foreign FOREIGN KEY (created_by) REFERENCES public.users(id_user) ON DELETE SET NULL;


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
-- Name: marketing_locations marketing_locations_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.marketing_locations
    ADD CONSTRAINT marketing_locations_user_id_foreign FOREIGN KEY (user_id) REFERENCES public.users(id_user) ON DELETE CASCADE;


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
-- Name: online_sale_items online_sale_items_online_sale_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.online_sale_items
    ADD CONSTRAINT online_sale_items_online_sale_id_foreign FOREIGN KEY (online_sale_id) REFERENCES public.online_sales(id) ON DELETE CASCADE;


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
-- PostgreSQL database dump complete
--

\unrestrict efpJFID6JUHPU7eYQF7CJUeSy7TkiJp9mRRsW2MacxIRVe8XPlTPXfloXeb1sqE

