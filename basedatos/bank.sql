--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.1
-- Dumped by pg_dump version 9.6.1

-- Started on 2019-11-30 03:59:45

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 1 (class 3079 OID 12387)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2313 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 2 (class 3079 OID 35270)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 2314 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET search_path = public, pg_catalog;

--
-- TOC entry 260 (class 1255 OID 35361)
-- Name: fc_generarrelease(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fc_generarrelease(text, text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
	DECLARE 
	-- HERLIN R. ESPINOSA G. 
	D_nombre ALIAS FOR $1;
	D_date ALIAS FOR $2;
	V_table text;
	R_sha256 text;
	Result RECORD;
	Result2 RECORD;
	Result3 RECORD;

	BEGIN 
		FOR Result IN 
			SELECT table_name FROM information_schema.COLUMNS WHERE table_schema = 'public' GROUP BY table_name
		LOOP
			SELECT INTO R_sha256 fc_sha256table(Result.table_name);
			INSERT INTO huella VALUES(DEFAULT,D_nombre,D_date,'Tabla/Vista',Result.table_name,R_sha256);
		END LOOP;


		FOR Result3 IN 
			SELECT routines.routine_name
			FROM information_schema.routines
			LEFT JOIN information_schema.parameters ON routines.specific_name=parameters.specific_name
			WHERE routines.specific_schema='public' AND routines.routine_name ILIKE ('fc_%')
			group by routines.routine_name
			ORDER BY routines.routine_name
		LOOP
			SELECT INTO R_sha256 fc_sha256function(Result3.routine_name);
			INSERT INTO huella VALUES(DEFAULT,D_nombre,D_date,'Funciones/Trigger',Result3.routine_name,R_sha256);
		END LOOP;
	END;

$_$;


ALTER FUNCTION public.fc_generarrelease(text, text) OWNER TO postgres;

--
-- TOC entry 259 (class 1255 OID 35310)
-- Name: fc_sha256function(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fc_sha256function(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
	DECLARE 
	-- HERLIN R. ESPINOSA G. 


	D_function ALIAS FOR $1;
	V_cad text;
	R_sha256 text;
	Result RECORD;

	BEGIN 
		V_cad := '';
		R_sha256 := '';
		FOR Result IN 
			SELECT (p.proname,pg_catalog.pg_get_function_result(p.oid),pg_catalog.pg_get_function_arguments(p.oid),p.prorettype) as fill
FROM pg_catalog.pg_proc p
     LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE pg_catalog.pg_function_is_visible(p.oid)
      AND n.nspname <> 'pg_catalog'
      AND n.nspname <> 'information_schema'
      AND p.proname = D_function
		LOOP
		V_cad := V_cad||Result.fill;
		END LOOP;

		SELECT INTO R_sha256 digest(V_cad, 'sha256');

		RETURN R_sha256;
		
	END;

$_$;


ALTER FUNCTION public.fc_sha256function(text) OWNER TO postgres;

--
-- TOC entry 257 (class 1255 OID 35330)
-- Name: fc_sha256sequence(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fc_sha256sequence(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
	DECLARE 
	-- HERLIN R. ESPINOSA G. 


	D_sequence ALIAS FOR $1;
	V_cad text;
	R_sha256 text;
	Result RECORD;

	BEGIN 
		V_cad := '';
		R_sha256 := '';
		FOR Result IN 
			select (sequence_name,data_type,numeric_precision,numeric_precision_radix,numeric_scale,start_value,minimum_value,maximum_value,increment) as fill from information_schema.sequences where sequence_name = D_sequence
		LOOP
		V_cad := V_cad||Result.fill;
		END LOOP;

		SELECT INTO R_sha256 digest(V_cad, 'sha256');

		RETURN R_sha256;
		
	END;

$_$;


ALTER FUNCTION public.fc_sha256sequence(text) OWNER TO postgres;

--
-- TOC entry 256 (class 1255 OID 35309)
-- Name: fc_sha256table(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fc_sha256table(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
	DECLARE 
	-- HERLIN R. ESPINOSA G. 


	D_table ALIAS FOR $1;
	V_cad text;
	R_sha256 text;
	Result RECORD;

	BEGIN 
		V_cad := '';
		R_sha256 := '';
		FOR Result IN 
			SELECT (table_name,ordinal_position,column_default,is_nullable,data_type,character_maximum_length,numeric_precision,numeric_precision_radix,numeric_scale) AS fill FROM information_schema.COLUMNS WHERE table_schema = 'public' AND table_name = D_table
		LOOP
		V_cad := V_cad||Result.fill;
		END LOOP;

		SELECT INTO R_sha256 digest(V_cad, 'sha256');

		RETURN R_sha256;
		
	END;

$_$;


ALTER FUNCTION public.fc_sha256table(text) OWNER TO postgres;

--
-- TOC entry 261 (class 1255 OID 35384)
-- Name: fc_validarrelease(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fc_validarrelease(text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
	DECLARE 
	-- HERLIN R. ESPINOSA G. 
	D_release ALIAS FOR $1;
	R_sha256 text;
	Result RECORD;
	Result2 RECORD;
	Result3 RECORD;

	BEGIN 
		FOR Result IN 
			select release,fecha,tipo,objecto,codigo, case tipo WHEN 'Tabla/Vista' THEN fc_sha256table(objecto) ELSE fc_sha256function(objecto) END AS codigo2 from huella where release = D_release
		LOOP
			SELECT INTO R_sha256 fc_sha256table(Result.objecto);
			INSERT INTO huella_tmp VALUES(DEFAULT,Result.release,Result.fecha,Result.tipo,Result.objecto,Result.codigo,Result.codigo2);
		END LOOP;

		
	END;

$_$;


ALTER FUNCTION public.fc_validarrelease(text) OWNER TO postgres;

--
-- TOC entry 258 (class 1255 OID 35327)
-- Name: log_last_name_changes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION log_last_name_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   IF NEW.last_name <> OLD.last_name THEN
       INSERT INTO employee_audits(employee_id,last_name,changed_on)
       VALUES(OLD.id,OLD.last_name,now());
   END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_last_name_changes() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 186 (class 1259 OID 35122)
-- Name: cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE cliente (
    clie_id numeric(30,0) NOT NULL,
    nombre character varying(151) NOT NULL,
    direccion character varying NOT NULL,
    telefono character varying NOT NULL,
    email character varying NOT NULL,
    activo character(1) NOT NULL,
    usu_creador character varying,
    fecha_creacion timestamp without time zone,
    usu_modificador character varying,
    fecha_modificacion timestamp without time zone,
    tdoc_id bigint,
    otra character(1)
);


ALTER TABLE cliente OWNER TO postgres;

--
-- TOC entry 189 (class 1259 OID 35142)
-- Name: cuenta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE cuenta (
    cuen_id character varying NOT NULL,
    saldo numeric(30,6),
    clave character varying NOT NULL,
    activa character(1),
    usu_creador character varying,
    fecha_creacion timestamp without time zone,
    usu_modificador character varying,
    fecha_modificacion timestamp without time zone,
    clie_id numeric(30,0)
);


ALTER TABLE cuenta OWNER TO postgres;

--
-- TOC entry 191 (class 1259 OID 35153)
-- Name: cuenta_registrada; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE cuenta_registrada (
    cure_id bigint NOT NULL,
    clie_id numeric(30,0),
    cuen_id character varying,
    activa character(1) NOT NULL,
    usu_creador character varying,
    fecha_creacion timestamp without time zone,
    usu_modificador character varying,
    fecha_modificacion timestamp without time zone
);


ALTER TABLE cuenta_registrada OWNER TO postgres;

--
-- TOC entry 190 (class 1259 OID 35151)
-- Name: cuenta_registrada_cure_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE cuenta_registrada_cure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cuenta_registrada_cure_id_seq OWNER TO postgres;

--
-- TOC entry 2315 (class 0 OID 0)
-- Dependencies: 190
-- Name: cuenta_registrada_cure_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE cuenta_registrada_cure_id_seq OWNED BY cuenta_registrada.cure_id;


--
-- TOC entry 202 (class 1259 OID 35321)
-- Name: employee_audits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE employee_audits (
    id integer NOT NULL,
    employee_id integer NOT NULL,
    last_name character varying(40) NOT NULL,
    changed_on timestamp(6) without time zone NOT NULL
);


ALTER TABLE employee_audits OWNER TO postgres;

--
-- TOC entry 201 (class 1259 OID 35319)
-- Name: employee_audits_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employee_audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE employee_audits_id_seq OWNER TO postgres;

--
-- TOC entry 2316 (class 0 OID 0)
-- Dependencies: 201
-- Name: employee_audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employee_audits_id_seq OWNED BY employee_audits.id;


--
-- TOC entry 200 (class 1259 OID 35313)
-- Name: employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE employees (
    id integer NOT NULL,
    first_name character varying(40) NOT NULL,
    last_name character varying(40) NOT NULL
);


ALTER TABLE employees OWNER TO postgres;

--
-- TOC entry 199 (class 1259 OID 35311)
-- Name: employees_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE employees_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE employees_id_seq OWNER TO postgres;

--
-- TOC entry 2317 (class 0 OID 0)
-- Dependencies: 199
-- Name: employees_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE employees_id_seq OWNED BY employees.id;


--
-- TOC entry 205 (class 1259 OID 35368)
-- Name: huella; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE huella (
    id bigint NOT NULL,
    release character varying(151) NOT NULL,
    fecha character varying NOT NULL,
    tipo character varying NOT NULL,
    objecto character varying NOT NULL,
    codigo text
);


ALTER TABLE huella OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 35366)
-- Name: huella_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE huella_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE huella_id_seq OWNER TO postgres;

--
-- TOC entry 2318 (class 0 OID 0)
-- Dependencies: 204
-- Name: huella_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE huella_id_seq OWNED BY huella.id;


--
-- TOC entry 207 (class 1259 OID 35387)
-- Name: huella_tmp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE huella_tmp (
    id bigint NOT NULL,
    release character varying(151) NOT NULL,
    fecha character varying NOT NULL,
    tipo character varying NOT NULL,
    objecto character varying NOT NULL,
    codigo text,
    codigo2 text
);


ALTER TABLE huella_tmp OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 35385)
-- Name: huella_tmp_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE huella_tmp_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE huella_tmp_id_seq OWNER TO postgres;

--
-- TOC entry 2319 (class 0 OID 0)
-- Dependencies: 206
-- Name: huella_tmp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE huella_tmp_id_seq OWNED BY huella_tmp.id;


--
-- TOC entry 188 (class 1259 OID 35133)
-- Name: tipo_documento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tipo_documento (
    tdoc_id bigint NOT NULL,
    nombre character varying NOT NULL,
    activo character(1) NOT NULL,
    usu_creador character varying,
    fecha_creacion timestamp without time zone,
    usu_modificador character varying,
    fecha_modificacion timestamp without time zone
);


ALTER TABLE tipo_documento OWNER TO postgres;

--
-- TOC entry 187 (class 1259 OID 35131)
-- Name: tipo_documento_tdoc_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tipo_documento_tdoc_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tipo_documento_tdoc_id_seq OWNER TO postgres;

--
-- TOC entry 2320 (class 0 OID 0)
-- Dependencies: 187
-- Name: tipo_documento_tdoc_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tipo_documento_tdoc_id_seq OWNED BY tipo_documento.tdoc_id;


--
-- TOC entry 198 (class 1259 OID 35200)
-- Name: tipo_transaccion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tipo_transaccion (
    titr_id bigint NOT NULL,
    nombre character varying NOT NULL,
    activo character(1) NOT NULL,
    usu_creador character varying,
    fecha_creacion timestamp without time zone,
    usu_modificador character varying,
    fecha_modificacion timestamp without time zone
);


ALTER TABLE tipo_transaccion OWNER TO postgres;

--
-- TOC entry 197 (class 1259 OID 35198)
-- Name: tipo_transaccion_titr_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tipo_transaccion_titr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tipo_transaccion_titr_id_seq OWNER TO postgres;

--
-- TOC entry 2321 (class 0 OID 0)
-- Dependencies: 197
-- Name: tipo_transaccion_titr_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tipo_transaccion_titr_id_seq OWNED BY tipo_transaccion.titr_id;


--
-- TOC entry 196 (class 1259 OID 35189)
-- Name: tipo_usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE tipo_usuario (
    tius_id bigint NOT NULL,
    nombre character varying NOT NULL,
    activo character(1) NOT NULL,
    usu_creador character varying,
    fecha_creacion timestamp without time zone,
    usu_modificador character varying,
    fecha_modificacion timestamp without time zone
);


ALTER TABLE tipo_usuario OWNER TO postgres;

--
-- TOC entry 195 (class 1259 OID 35187)
-- Name: tipo_usuario_tius_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE tipo_usuario_tius_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE tipo_usuario_tius_id_seq OWNER TO postgres;

--
-- TOC entry 2322 (class 0 OID 0)
-- Dependencies: 195
-- Name: tipo_usuario_tius_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE tipo_usuario_tius_id_seq OWNED BY tipo_usuario.tius_id;


--
-- TOC entry 193 (class 1259 OID 35166)
-- Name: transaccion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE transaccion (
    tran_id bigint NOT NULL,
    cuen_id character varying,
    valor numeric(30,6) NOT NULL,
    fecha timestamp without time zone NOT NULL,
    usu_usuario character varying,
    titr_id bigint,
    usu_creador character varying,
    fecha_creacion timestamp without time zone,
    usu_modificador character varying,
    fecha_modificacion timestamp without time zone
);


ALTER TABLE transaccion OWNER TO postgres;

--
-- TOC entry 192 (class 1259 OID 35164)
-- Name: transaccion_tran_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE transaccion_tran_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE transaccion_tran_id_seq OWNER TO postgres;

--
-- TOC entry 2323 (class 0 OID 0)
-- Dependencies: 192
-- Name: transaccion_tran_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE transaccion_tran_id_seq OWNED BY transaccion.tran_id;


--
-- TOC entry 194 (class 1259 OID 35178)
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE usuario (
    usu_usuario character varying NOT NULL,
    clave character varying NOT NULL,
    identificacion numeric(30,0) NOT NULL,
    nombre character varying NOT NULL,
    activo character(1) NOT NULL,
    usu_creador character varying,
    fecha_creacion timestamp without time zone,
    usu_modificador character varying,
    fecha_modificacion timestamp without time zone,
    tius_id bigint
);


ALTER TABLE usuario OWNER TO postgres;

--
-- TOC entry 203 (class 1259 OID 35335)
-- Name: vw_cliente_simple; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW vw_cliente_simple AS
 SELECT cliente.clie_id,
    cliente.nombre
   FROM cliente;


ALTER TABLE vw_cliente_simple OWNER TO postgres;

--
-- TOC entry 2119 (class 2604 OID 35156)
-- Name: cuenta_registrada cure_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cuenta_registrada ALTER COLUMN cure_id SET DEFAULT nextval('cuenta_registrada_cure_id_seq'::regclass);


--
-- TOC entry 2124 (class 2604 OID 35324)
-- Name: employee_audits id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_audits ALTER COLUMN id SET DEFAULT nextval('employee_audits_id_seq'::regclass);


--
-- TOC entry 2123 (class 2604 OID 35316)
-- Name: employees id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees ALTER COLUMN id SET DEFAULT nextval('employees_id_seq'::regclass);


--
-- TOC entry 2125 (class 2604 OID 35371)
-- Name: huella id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY huella ALTER COLUMN id SET DEFAULT nextval('huella_id_seq'::regclass);


--
-- TOC entry 2126 (class 2604 OID 35390)
-- Name: huella_tmp id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY huella_tmp ALTER COLUMN id SET DEFAULT nextval('huella_tmp_id_seq'::regclass);


--
-- TOC entry 2118 (class 2604 OID 35136)
-- Name: tipo_documento tdoc_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tipo_documento ALTER COLUMN tdoc_id SET DEFAULT nextval('tipo_documento_tdoc_id_seq'::regclass);


--
-- TOC entry 2122 (class 2604 OID 35203)
-- Name: tipo_transaccion titr_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tipo_transaccion ALTER COLUMN titr_id SET DEFAULT nextval('tipo_transaccion_titr_id_seq'::regclass);


--
-- TOC entry 2121 (class 2604 OID 35192)
-- Name: tipo_usuario tius_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tipo_usuario ALTER COLUMN tius_id SET DEFAULT nextval('tipo_usuario_tius_id_seq'::regclass);


--
-- TOC entry 2120 (class 2604 OID 35169)
-- Name: transaccion tran_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaccion ALTER COLUMN tran_id SET DEFAULT nextval('transaccion_tran_id_seq'::regclass);


--
-- TOC entry 2286 (class 0 OID 35122)
-- Dependencies: 186
-- Data for Name: cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO cliente VALUES (1, 'Humfried Downes', '94 Hintze Drive', '62-(594)716-0300', 'hdownes0@bloomberg.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (3, 'Andris Waulker', '7 Dottie Hill', '86-(583)590-5410', 'awaulker2@seesaa.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (5, 'Igor Bittlestone', '7641 Oak Center', '66-(589)556-9113', 'ibittlestone4@uol.com.br', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (6, 'Daryl Saye', '6483 Hagan Street', '27-(786)583-6780', 'dsaye5@home.pl', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (7, 'Jourdain Carty', '0 Golden Leaf Court', '351-(491)611-7301', 'jcarty6@latimes.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (8, 'Kira Grinyov', '0 Tony Center', '86-(839)336-9808', 'kgrinyov7@sciencedaily.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (9, 'Ernestine Debrett', '96 Di Loreto Junction', '353-(207)786-3961', 'edebrett8@yelp.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (10, 'Vincent Kierans', '6098 Harbort Street', '33-(937)517-1669', 'vkierans9@theglobeandmail.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (11, 'Ephrem Pearmain', '019 Loomis Pass', '54-(695)284-5063', 'epearmaina@t-online.de', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (12, 'Damien Hanbidge', '001 Macpherson Road', '7-(698)695-0384', 'dhanbidgeb@un.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (13, 'Beryle Chave', '46366 Mccormick Court', '62-(382)601-8090', 'bchavec@wikimedia.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (14, 'Ozzie Clench', '1119 Mosinee Hill', '351-(653)215-2254', 'oclenchd@last.fm', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (15, 'Editha Swinburne', '17 Schmedeman Pass', '62-(524)287-7571', 'eswinburnee@dedecms.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (16, 'Teresina Rassmann', '5478 Ridgeway Road', '504-(651)585-2907', 'trassmannf@plala.or.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (17, 'Carlos Boyne', '910 Nova Center', '420-(806)408-2470', 'cboyneg@amazonaws.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (18, 'Wynny Skouling', '63147 Holmberg Place', '46-(399)275-1214', 'wskoulingh@netscape.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (19, 'Ingaberg Brando', '847 Badeau Center', '63-(123)978-3020', 'ibrandoi@mediafire.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (20, 'Bell Wolfendale', '54 Sunbrook Road', '27-(677)685-8996', 'bwolfendalej@drupal.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (21, 'Marguerite Haville', '7706 Maple Park', '975-(882)536-0941', 'mhavillek@homestead.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (22, 'Lil Arpe', '20590 Pearson Plaza', '48-(184)163-8483', 'larpel@joomla.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (23, 'Darn MacWhirter', '4 American Point', '386-(261)708-9360', 'dmacwhirterm@hubpages.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (24, 'Faythe Leggis', '979 Graceland Lane', '7-(568)513-8038', 'fleggisn@desdev.cn', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (25, 'Vin Jacobssen', '00593 Westerfield Crossing', '86-(774)469-5559', 'vjacobsseno@zimbio.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (26, 'Emmey Mazzia', '32806 Stone Corner Terrace', '63-(354)537-1009', 'emazziap@ow.ly', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (27, 'Gerladina Messenger', '5 Banding Lane', '86-(644)205-8434', 'gmessengerq@fema.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (28, 'Cointon Abramowsky', '86 Elgar Parkway', '86-(402)630-9092', 'cabramowskyr@netvibes.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (29, 'Moss Annakin', '69 Elka Circle', '62-(385)662-5356', 'mannakins@newsvine.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (30, 'Thadeus Osgood', '073 Sundown Point', '86-(738)310-2323', 'tosgoodt@unblog.fr', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (31, 'Anni Kewley', '92931 Linden Trail', '7-(495)264-6498', 'akewleyu@cbc.ca', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (32, 'Ursulina Tapin', '886 Macpherson Lane', '62-(947)967-7938', 'utapinv@bigcartel.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (33, 'Hamel Smorthit', '1 Nancy Center', '976-(629)689-5720', 'hsmorthitw@reuters.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (34, 'Tim Canlin', '98 Mandrake Pass', '86-(978)384-6616', 'tcanlinx@bloomberg.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (35, 'Eddie Wrintmore', '46105 Arrowood Crossing', '58-(788)905-3913', 'ewrintmorey@sina.com.cn', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (36, 'Tatiania Vasyutin', '1669 Lakewood Park', '54-(185)510-2537', 'tvasyutinz@instagram.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (37, 'Clem Cowterd', '65 Jay Road', '86-(666)220-6495', 'ccowterd10@samsung.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (38, 'Roderigo Gosse', '1 Ridgeway Hill', '86-(695)587-7738', 'rgosse11@shop-pro.jp', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (39, 'Nadiya Vannuccini', '708 Spaight Hill', '385-(647)734-1436', 'nvannuccini12@adobe.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (40, 'Horace MacCague', '5 Prairie Rose Terrace', '590-(697)205-3593', 'hmaccague13@google.es', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (41, 'Nola Liff', '1095 Thackeray Point', '46-(769)819-3898', 'nliff14@dagondesign.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (42, 'Peadar McCaughey', '2151 Farmco Parkway', '351-(477)389-6414', 'pmccaughey15@businessinsider.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (43, 'Gualterio Pockey', '73 Arapahoe Lane', '86-(962)241-2903', 'gpockey16@github.io', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (44, 'Hedy Dunmuir', '45280 Mayer Terrace', '62-(319)112-6324', 'hdunmuir17@live.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (45, 'Launce Phlippsen', '6 Hoffman Pass', '351-(269)178-2117', 'lphlippsen18@php.net', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (46, 'Pia Larratt', '0 Melvin Park', '62-(609)350-7545', 'plarratt19@posterous.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (47, 'Alan de Zamora', '319 Roxbury Drive', '62-(594)103-9054', 'ade1a@moonfruit.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (48, 'Shani Danneil', '4759 Gulseth Junction', '370-(539)690-2592', 'sdanneil1b@telegraph.co.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (49, 'Griffy Linggood', '2405 Coleman Court', '7-(188)180-1426', 'glinggood1c@networksolutions.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (50, 'Katerina Bilbrooke', '0338 Buhler Junction', '48-(149)115-4273', 'kbilbrooke1d@hibu.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (51, 'Si Crewes', '74785 Express Avenue', '7-(239)143-0022', 'screwes1e@nbcnews.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (52, 'Tuck Pauler', '6 Ridge Oak Alley', '86-(130)905-2330', 'tpauler1f@cbsnews.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (53, 'Knox Dytham', '4603 Helena Trail', '84-(942)602-3732', 'kdytham1g@examiner.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (54, 'Urbanus Imos', '9189 Kennedy Plaza', '86-(383)655-5328', 'uimos1h@pcworld.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (55, 'Vaclav Van der Krui', '9608 Northwestern Way', '63-(404)706-2136', 'vvan1i@google.it', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (56, 'Margy Wyon', '67236 Stang Parkway', '86-(708)100-0242', 'mwyon1j@seesaa.net', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (57, 'Karon Caton', '3 Oak Crossing', '251-(448)548-2113', 'kcaton1k@uol.com.br', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (58, 'Eada MacRinn', '2459 Nova Road', '353-(824)204-4646', 'emacrinn1l@amazon.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (59, 'Dulcia Leer', '58 Graceland Trail', '86-(288)136-6744', 'dleer1m@fema.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (60, 'Claire Ruffy', '0 Welch Point', '973-(596)502-2593', 'cruffy1n@plala.or.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (61, 'Walton O''Cahey', '00364 Sloan Parkway', '45-(136)526-6291', 'wocahey1o@ca.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (62, 'Idette Fessions', '0887 Bayside Court', '86-(205)925-5840', 'ifessions1p@mediafire.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (63, 'Mischa Danilchev', '553 Londonderry Drive', '33-(255)642-1823', 'mdanilchev1q@fda.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (64, 'Shaylynn Durie', '24418 Clarendon Circle', '212-(887)604-2627', 'sdurie1r@hugedomains.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (4, 'Karole Dunge', '291 Sycamore Hill', '7-(303)913-5438', 'kdunge3@theguardian.com', 'N', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (65, 'Jean Downing', '7496 Longview Park', '33-(787)247-7520', 'jdowning1s@prweb.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (66, 'Ferne Bulger', '2311 Columbus Street', '62-(666)523-2328', 'fbulger1t@hibu.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (67, 'Shawnee Fearon', '33 Barby Alley', '62-(961)265-2623', 'sfearon1u@wordpress.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (68, 'Bonny Milsted', '301 Eggendart Parkway', '420-(616)384-8214', 'bmilsted1v@paginegialle.it', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (69, 'Barnabe Bohling', '3 Shoshone Parkway', '420-(521)209-1950', 'bbohling1w@bizjournals.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (70, 'Liza Waymont', '0 Esker Way', '30-(575)187-3838', 'lwaymont1x@51.la', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (71, 'Tabby Youings', '71078 Anniversary Pass', '46-(757)636-5225', 'tyouings1y@domainmarket.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (72, 'Chaim Witton', '429 Forest Plaza', '54-(286)313-8044', 'cwitton1z@dmoz.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (73, 'Arie D''Oyley', '3235 Grasskamp Parkway', '55-(817)803-7750', 'adoyley20@linkedin.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (74, 'Lothario Matton', '71 Badeau Way', '964-(738)550-2184', 'lmatton21@bbc.co.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (75, 'Amber Skeat', '2 Utah Parkway', '385-(284)422-3055', 'askeat22@unc.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (76, 'Derril MacKeig', '875 North Street', '63-(498)610-5910', 'dmackeig23@psu.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (77, 'Wallace Davydochkin', '8049 Bowman Avenue', '7-(562)222-0263', 'wdavydochkin24@shutterfly.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (78, 'Brock Parade', '7917 Transport Way', '351-(764)404-4044', 'bparade25@rambler.ru', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (79, 'Jdavie Vanyashkin', '52536 Menomonie Center', '976-(386)324-5059', 'jvanyashkin26@ca.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (80, 'Lily Kelbie', '86 Shopko Circle', '966-(799)421-3033', 'lkelbie27@booking.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (81, 'Dalia Ecclestone', '64931 Hazelcrest Drive', '63-(272)211-8290', 'decclestone28@wufoo.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (82, 'Kaylil Wrigley', '06 Dixon Court', '351-(688)990-7853', 'kwrigley29@smugmug.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (83, 'Garold Trynor', '072 Everett Park', '995-(541)608-7224', 'gtrynor2a@a8.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (84, 'Barclay Buyers', '07 Merchant Drive', '63-(773)781-1059', 'bbuyers2b@taobao.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (85, 'Savina Eve', '20 Norway Maple Lane', '86-(141)143-9126', 'seve2c@answers.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (86, 'Conrade Clemanceau', '52 Cherokee Place', '55-(864)338-9258', 'cclemanceau2d@altervista.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (87, 'Dell Audrey', '82 Petterle Center', '55-(925)516-0978', 'daudrey2e@storify.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (88, 'Glenn McIvor', '06 Bluestem Center', '33-(698)297-5832', 'gmcivor2f@nih.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (89, 'Lars Beri', '6 Grasskamp Point', '86-(541)190-0751', 'lberi2g@ning.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (90, 'Leeann McElhinney', '79844 Express Drive', '86-(995)152-4934', 'lmcelhinney2h@dedecms.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (91, 'Marvin Westwell', '225 Dovetail Pass', '55-(980)902-6002', 'mwestwell2i@symantec.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (92, 'Nanci Dodridge', '3176 Carpenter Place', '7-(171)951-1592', 'ndodridge2j@kickstarter.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (93, 'Maddi Daish', '1517 Haas Road', '33-(477)364-6312', 'mdaish2k@miitbeian.gov.cn', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (94, 'Fabien Dell', '78 Vahlen Pass', '232-(613)894-8375', 'fdell2l@geocities.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (95, 'Julie Lowless', '396 Hayes Point', '62-(504)431-8001', 'jlowless2m@t-online.de', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (96, 'Fran Bison', '0380 Susan Parkway', '55-(844)902-6984', 'fbison2n@umn.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (97, 'Maynord Berrick', '8188 Bobwhite Street', '62-(893)305-4231', 'mberrick2o@ehow.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (98, 'Alexandr Every', '58 Kings Hill', '351-(432)797-5882', 'aevery2p@typepad.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (99, 'Jodie Willder', '72 Summer Ridge Circle', '1-(650)484-0886', 'jwillder2q@netscape.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (100, 'Perren Kalaher', '1 Dryden Crossing', '86-(671)257-8491', 'pkalaher2r@live.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (101, 'Rob Rolles', '9 Forest Road', '62-(593)409-6209', 'rrolles2s@drupal.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (102, 'Addi Ribeiro', '400 Hagan Way', '86-(875)111-7034', 'aribeiro2t@mediafire.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (103, 'Kelbee Piddle', '0160 Gateway Drive', '351-(390)297-2074', 'kpiddle2u@devhub.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (104, 'Torre Cary', '3858 Larry Hill', '84-(578)632-9853', 'tcary2v@php.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (105, 'Corbett Peres', '7 Nancy Point', '62-(622)999-0725', 'cperes2w@naver.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (106, 'Waly Sowrah', '6 Moose Road', '86-(423)861-7272', 'wsowrah2x@youtube.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (107, 'Jeniece Seine', '1255 Northland Lane', '86-(971)937-4214', 'jseine2y@washingtonpost.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (108, 'Karia Acome', '60192 Morrow Road', '62-(696)498-2818', 'kacome2z@abc.net.au', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (109, 'Carleton Jovicevic', '69 Havey Crossing', '351-(195)753-0288', 'cjovicevic30@biblegateway.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (110, 'Jasmin Nardoni', '0 Pierstorff Pass', '55-(237)409-3781', 'jnardoni31@ed.gov', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (111, 'Zandra Grangier', '362 Heffernan Crossing', '48-(990)960-8286', 'zgrangier32@eventbrite.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (112, 'Marijo D''Oyley', '14 Forster Plaza', '93-(890)902-3802', 'mdoyley33@yellowbook.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (113, 'Tades Weth', '70 Fairfield Plaza', '55-(156)528-1862', 'tweth34@google.de', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (114, 'Josey Whenman', '4 Reindahl Way', '86-(203)183-2926', 'jwhenman35@europa.eu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (115, 'Caresa Praill', '050 Moose Terrace', '86-(988)191-9873', 'cpraill36@fotki.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (116, 'Eloise Cleeve', '0 Manley Trail', '389-(552)704-1359', 'ecleeve37@jalbum.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (117, 'Alissa Bonnesen', '9 Clemons Road', '86-(114)383-1656', 'abonnesen38@intel.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (118, 'Leoline Cowndley', '39 Mendota Street', '62-(241)437-9508', 'lcowndley39@bloglovin.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (119, 'Jaynell Keyden', '09 Kensington Parkway', '46-(597)496-3858', 'jkeyden3a@theglobeandmail.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (120, 'Rochella Bhar', '75 Dwight Lane', '43-(361)122-8554', 'rbhar3b@tripadvisor.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (121, 'Lory Allabarton', '598 East Pass', '55-(836)808-2035', 'lallabarton3c@sohu.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (122, 'Elnore Wadwell', '2 Mifflin Crossing', '51-(969)305-3562', 'ewadwell3d@barnesandnoble.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (123, 'Neda Seifert', '64 Alpine Center', '375-(463)380-8836', 'nseifert3e@cornell.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (124, 'Laurel Hryskiewicz', '159 Haas Circle', '86-(832)107-3616', 'lhryskiewicz3f@usda.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (125, 'Bride Timcke', '612 Lakeland Alley', '380-(875)576-2254', 'btimcke3g@comcast.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (126, 'Sammy Westpfel', '2327 Algoma Place', '54-(881)291-2482', 'swestpfel3h@tinypic.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (127, 'Costanza Meharry', '97735 Kropf Lane', '48-(742)448-9563', 'cmeharry3i@cdbaby.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (128, 'Estelle Claybourne', '9481 Bunker Hill Hill', '7-(966)446-5002', 'eclaybourne3j@thetimes.co.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (129, 'Dru Dorrell', '352 Corben Road', '63-(386)274-2863', 'ddorrell3k@studiopress.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (130, 'Westley Mourge', '0 Mosinee Pass', '674-(713)418-0166', 'wmourge3l@cam.ac.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (131, 'Corenda Walbrook', '9 Di Loreto Terrace', '507-(655)164-8686', 'cwalbrook3m@stumbleupon.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (132, 'Lissy Lathom', '155 Cascade Hill', '55-(494)175-8739', 'llathom3n@php.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (133, 'Rickard Santus', '8 Oxford Terrace', '86-(870)154-9253', 'rsantus3o@europa.eu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (134, 'Filmer Hopewell', '0706 Crest Line Drive', '351-(894)362-6548', 'fhopewell3p@soundcloud.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (135, 'Ario Kharchinski', '67 Crowley Lane', '355-(280)576-5762', 'akharchinski3q@pcworld.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (136, 'Karleen Sterte', '77 East Court', '62-(182)356-5840', 'ksterte3r@artisteer.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (137, 'Tabb Iwaszkiewicz', '0837 Wayridge Center', '30-(136)695-5606', 'tiwaszkiewicz3s@nydailynews.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (138, 'Donetta Morriss', '70 Commercial Trail', '380-(947)339-9717', 'dmorriss3t@house.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (139, 'Stacy Elcoux', '789 Northridge Crossing', '86-(790)944-6032', 'selcoux3u@vistaprint.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (140, 'Darrel Rodolphe', '316 Loomis Road', '86-(791)909-2819', 'drodolphe3v@google.com.br', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (141, 'Gratia Ballham', '0 Pearson Point', '86-(659)202-6889', 'gballham3w@samsung.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (142, 'Christoforo Beckingham', '1 Hooker Terrace', '244-(650)171-9606', 'cbeckingham3x@bing.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (143, 'Rolf Caffin', '21 Sommers Drive', '976-(296)351-4812', 'rcaffin3y@nymag.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (144, 'Dena Mulqueen', '799 Hovde Point', '51-(596)498-2402', 'dmulqueen3z@opensource.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (145, 'Adham MacCoveney', '5605 Clyde Gallagher Trail', '27-(922)603-5412', 'amaccoveney40@qq.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (146, 'Colan Di Angelo', '683 Summer Ridge Alley', '351-(799)887-5454', 'cdi41@furl.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (147, 'Taite Cartmail', '09 Sunfield Place', '86-(595)732-5204', 'tcartmail42@webs.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (148, 'Alano Wemyss', '92 Autumn Leaf Circle', '51-(426)859-4411', 'awemyss43@opera.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (149, 'Boris Pietersen', '636 Grasskamp Circle', '962-(171)856-1595', 'bpietersen44@comsenz.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (150, 'Kristofer Cavee', '342 Golf View Court', '241-(967)841-2093', 'kcavee45@cocolog-nifty.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (151, 'Rivalee Pepon', '9 Cherokee Avenue', '55-(350)722-5711', 'rpepon46@posterous.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (152, 'Farr Izzatt', '35024 Hoepker Alley', '86-(835)144-2943', 'fizzatt47@plala.or.jp', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (153, 'Mickey Cardiff', '85822 Brown Parkway', '54-(944)331-5927', 'mcardiff48@nymag.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (154, 'Korey Andreaccio', '105 Arizona Junction', '63-(223)726-1744', 'kandreaccio49@reference.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (155, 'Fifine Huscroft', '38 Dawn Crossing', '355-(915)891-3408', 'fhuscroft4a@wufoo.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (156, 'Frasier Rollin', '23 Maryland Junction', '7-(807)984-0450', 'frollin4b@wp.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (157, 'Ber Game', '10759 Hollow Ridge Alley', '33-(546)485-2681', 'bgame4c@barnesandnoble.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (158, 'Corrie Winsome', '244 Graedel Alley', '356-(660)765-7275', 'cwinsome4d@seesaa.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (159, 'Carilyn Coote', '8 Luster Center', '51-(374)663-8951', 'ccoote4e@unicef.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (160, 'Karolina Sturror', '6 Sherman Pass', '7-(896)879-8336', 'ksturror4f@google.de', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (161, 'Fabiano Simeone', '58278 Oneill Terrace', '86-(402)184-4526', 'fsimeone4g@tuttocitta.it', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (162, 'Louis De Hooch', '1 Shelley Pass', '254-(356)361-3823', 'lde4h@csmonitor.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (163, 'Guido Farguhar', '223 Maryland Lane', '36-(212)304-2063', 'gfarguhar4i@umn.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (164, 'Gustav Magog', '96824 Vera Crossing', '54-(867)420-7560', 'gmagog4j@netvibes.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (165, 'Ragnar Dykins', '78058 Merchant Point', '7-(176)395-6906', 'rdykins4k@ed.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (166, 'Corinna Emnoney', '3 Melody Junction', '598-(214)421-5071', 'cemnoney4l@berkeley.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (167, 'Felic Perotti', '3 7th Drive', '48-(414)147-9407', 'fperotti4m@github.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (168, 'Tammie Haddrill', '3 Meadow Vale Hill', '351-(975)321-6956', 'thaddrill4n@tamu.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (169, 'Bordy Crowden', '2662 Spohn Junction', '380-(474)625-1241', 'bcrowden4o@cnet.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (170, 'Bari Bushen', '87367 Pond Park', '86-(324)920-7953', 'bbushen4p@soundcloud.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (171, 'Gustie Stolz', '7 Ludington Center', '66-(315)728-4841', 'gstolz4q@qq.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (172, 'Rockie Heugle', '2917 Esch Parkway', '48-(584)594-0186', 'rheugle4r@accuweather.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (173, 'Margarita Guerra', '0039 Scott Road', '46-(867)922-3541', 'mguerra4s@nba.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (174, 'Alfy MacCome', '9 Little Fleur Junction', '7-(244)189-3194', 'amaccome4t@indiegogo.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (175, 'Egor Blei', '1827 Valley Edge Parkway', '237-(656)155-4144', 'eblei4u@dagondesign.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (176, 'Gav Fortnon', '10 Ramsey Junction', '689-(227)100-8771', 'gfortnon4v@reuters.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (177, 'Mady Huxley', '68804 Fulton Hill', '84-(637)658-1677', 'mhuxley4w@indiegogo.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (178, 'Molly Dwyr', '15639 Shoshone Alley', '81-(721)624-1178', 'mdwyr4x@dagondesign.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (179, 'Murray Aickin', '62 Briar Crest Terrace', '1-(423)219-3159', 'maickin4y@pbs.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (180, 'Barrie Castelijn', '6046 Badeau Terrace', '7-(932)141-7884', 'bcastelijn4z@vimeo.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (181, 'Terry Yakobowitch', '644 Swallow Circle', '1-(251)669-1642', 'tyakobowitch50@technorati.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (182, 'Reeva Lacoste', '00575 Summerview Lane', '84-(748)305-5914', 'rlacoste51@chronoengine.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (183, 'Dorthy Forbear', '3075 Springs Center', '62-(513)853-1547', 'dforbear52@posterous.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (184, 'Moshe Wones', '608 Mitchell Crossing', '7-(177)674-6293', 'mwones53@nymag.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (185, 'Scotty Mattingly', '02 Stang Point', '86-(132)264-2118', 'smattingly54@phoca.cz', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (186, 'Trefor De Giorgio', '42 Transport Hill', '370-(113)865-1390', 'tde55@discovery.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (187, 'Barny Asals', '244 Anthes Street', '1-(256)342-1919', 'basals56@icio.us', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (188, 'Brett Mullenger', '03362 Grayhawk Center', '1-(313)465-7404', 'bmullenger57@woothemes.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (189, 'Fraze Stivani', '0 Towne Drive', '86-(171)145-0530', 'fstivani58@live.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (190, 'Arley Lokier', '2403 Corry Terrace', '31-(899)101-5837', 'alokier59@shareasale.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (191, 'Sansone Krzysztof', '81 Hollow Ridge Pass', '49-(224)735-8141', 'skrzysztof5a@home.pl', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (192, 'Pearline Hamnett', '8554 Fairview Street', '251-(295)862-3184', 'phamnett5b@mapy.cz', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (193, 'Farlee Tarply', '910 Susan Lane', '62-(414)475-2599', 'ftarply5c@hao123.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (194, 'Mack Stanyer', '7 Florence Hill', '58-(209)361-6317', 'mstanyer5d@amazon.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (195, 'Keelby Grand', '5 Kipling Alley', '244-(356)480-8637', 'kgrand5e@bloglovin.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (196, 'Ellswerth Mixworthy', '19717 Truax Street', '55-(860)982-0727', 'emixworthy5f@slashdot.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (197, 'Priscilla Raye', '07 Mandrake Park', '236-(625)149-4527', 'praye5g@tinypic.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (198, 'Darwin Berkowitz', '0391 Sycamore Trail', '62-(961)480-0102', 'dberkowitz5h@newyorker.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (199, 'Jethro Shapcott', '5248 6th Place', '687-(893)944-1720', 'jshapcott5i@dagondesign.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (200, 'Marquita Hattrick', '9197 Golf Place', '227-(657)316-8013', 'mhattrick5j@umn.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (201, 'Yul Camerello', '99976 Messerschmidt Park', '505-(602)990-9945', 'ycamerello5k@taobao.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (202, 'Alta Durrad', '09235 Nancy Park', '7-(658)848-7072', 'adurrad5l@senate.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (203, 'Farlee MacCheyne', '02962 Morningstar Junction', '86-(552)352-6796', 'fmaccheyne5m@vkontakte.ru', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (204, 'Adeline Yegorev', '4 Memorial Crossing', '380-(427)657-6732', 'ayegorev5n@biblegateway.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (205, 'Shirl Ferreras', '2731 Knutson Plaza', '62-(162)319-7426', 'sferreras5o@psu.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (206, 'Selestina Treasaden', '491 Truax Crossing', '351-(947)114-6329', 'streasaden5p@com.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (207, 'Guinna Crafter', '36 Hovde Trail', '374-(707)109-5904', 'gcrafter5q@bloomberg.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (208, 'Eda D''Acth', '2790 Swallow Circle', '52-(864)683-9468', 'edacth5r@toplist.cz', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (209, 'Norri Vowles', '84 Clarendon Lane', '63-(953)642-9356', 'nvowles5s@dion.ne.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (210, 'Manya Emeny', '9 Hintze Pass', '420-(123)388-0246', 'memeny5t@jimdo.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (211, 'Delainey Larrad', '88 Stang Trail', '86-(351)381-6107', 'dlarrad5u@gmpg.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (212, 'Osmond Laister', '16 Corben Court', '55-(315)301-4524', 'olaister5v@surveymonkey.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (213, 'Dredi Gowdridge', '61143 Dayton Alley', '30-(948)763-6869', 'dgowdridge5w@over-blog.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (214, 'Jacky Castillou', '836 Summer Ridge Hill', '62-(252)915-3384', 'jcastillou5x@sina.com.cn', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (215, 'Marlow Baily', '1 Barnett Hill', '86-(457)128-7292', 'mbaily5y@goodreads.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (216, 'Claudell Hennemann', '221 Harbort Point', '46-(152)698-8498', 'chennemann5z@ihg.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (217, 'Darnall Gogin', '5215 Maryland Junction', '46-(490)180-2846', 'dgogin60@whitehouse.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (218, 'Tessa Gasparro', '917 Rockefeller Road', '46-(754)241-0334', 'tgasparro61@etsy.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (219, 'Hayes Van Waadenburg', '5213 Kingsford Alley', '386-(572)126-0151', 'hvan62@shop-pro.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (220, 'Netta Semper', '303 New Castle Drive', '351-(555)400-3947', 'nsemper63@blogger.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (221, 'Ibby Palleske', '38714 Dwight Park', '62-(242)992-8741', 'ipalleske64@sohu.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (222, 'Ethelin Bly', '11582 8th Place', '86-(616)640-7752', 'ebly65@goo.ne.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (223, 'Kelly Fiddymont', '4473 Stang Lane', '63-(248)218-4238', 'kfiddymont66@fema.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (224, 'Blakeley Dany', '5 Division Point', '261-(489)668-2203', 'bdany67@fotki.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (225, 'Dyana Carrabott', '81177 Merchant Point', '55-(151)844-8856', 'dcarrabott68@qq.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (226, 'Kory Worsnap', '36276 Hoepker Court', '45-(538)655-1646', 'kworsnap69@salon.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (227, 'Augustine Fattorini', '228 Debs Pass', '86-(702)989-5405', 'afattorini6a@biblegateway.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (228, 'Seth Tellenbrook', '1403 Manufacturers Terrace', '55-(744)116-1500', 'stellenbrook6b@nydailynews.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (229, 'Charlotte Casone', '754 American Terrace', '62-(969)188-0555', 'ccasone6c@pagesperso-orange.fr', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (230, 'Martina Stollmeier', '7249 Kropf Trail', '86-(290)744-5109', 'mstollmeier6d@comsenz.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (231, 'Brynna Matthisson', '6 Derek Avenue', '55-(501)151-6904', 'bmatthisson6e@acquirethisname.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (232, 'Selie Goldwater', '582 Quincy Plaza', '420-(260)888-4045', 'sgoldwater6f@blogtalkradio.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (233, 'Sonia Hauger', '40 Monterey Park', '251-(551)941-7644', 'shauger6g@dedecms.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (234, 'Natividad Abyss', '86 Spaight Court', '33-(689)195-9629', 'nabyss6h@addtoany.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (235, 'Keenan Johnke', '8548 Sycamore Trail', '1-(408)161-2323', 'kjohnke6i@goodreads.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (236, 'Herve Lake', '2 Springview Way', '55-(499)447-7324', 'hlake6j@gizmodo.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (237, 'Lissa Barney', '61070 Northfield Road', '66-(399)382-6655', 'lbarney6k@fotki.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (238, 'Noreen Cant', '2703 Chive Point', '380-(596)542-7045', 'ncant6l@amazon.de', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (239, 'Pascale Kerfut', '62 Eggendart Place', '86-(237)766-0333', 'pkerfut6m@photobucket.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (240, 'Carmelle Steely', '5308 Sommers Junction', '46-(515)707-9474', 'csteely6n@typepad.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (241, 'Linnea McColl', '46 Gateway Street', '420-(798)922-4812', 'lmccoll6o@sbwire.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (242, 'Jojo MacRirie', '07 Dexter Avenue', '62-(324)936-1810', 'jmacririe6p@over-blog.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (243, 'Tarra Baldoni', '1 Haas Court', '371-(557)835-9193', 'tbaldoni6q@google.pl', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (244, 'Lorraine Marzellano', '856 Hudson Way', '261-(886)963-4760', 'lmarzellano6r@mail.ru', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (245, 'Elissa McGrane', '677 Corscot Point', '355-(659)358-5015', 'emcgrane6s@chron.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (246, 'Rollin Jobe', '5529 Morrow Plaza', '58-(808)624-2568', 'rjobe6t@sciencedirect.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (247, 'Ebony Dunkirk', '2 Fair Oaks Avenue', '46-(483)752-9949', 'edunkirk6u@sbwire.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (248, 'Akim Ironside', '65 Gateway Parkway', '62-(674)728-2755', 'aironside6v@soup.io', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (249, 'Dolly Jouannin', '937 Maywood Alley', '374-(169)244-1379', 'djouannin6w@odnoklassniki.ru', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (250, 'Torey Joiner', '43 Towne Place', '62-(818)423-5153', 'tjoiner6x@army.mil', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (251, 'Mitchell Cash', '2 Gulseth Drive', '48-(341)522-1884', 'mcash6y@php.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (252, 'Bernhard Fosdick', '562 Stang Junction', '20-(146)851-5718', 'bfosdick6z@dmoz.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (253, 'Wenda De Leek', '884 Farwell Crossing', '351-(129)181-7979', 'wde70@samsung.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (254, 'Berthe Barkworth', '92 Brown Alley', '86-(938)707-5597', 'bbarkworth71@multiply.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (255, 'Joachim Methven', '84163 Esch Trail', '351-(257)467-0531', 'jmethven72@engadget.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (256, 'Beck Gallon', '93 Northland Avenue', '51-(558)422-7635', 'bgallon73@bbc.co.uk', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (257, 'Adriena MacGilfoyle', '00 Merry Street', '86-(255)744-5293', 'amacgilfoyle74@latimes.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (258, 'Kyle Brodley', '83 Basil Park', '7-(723)872-0181', 'kbrodley75@facebook.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (259, 'Gwyneth Shovel', '14836 Sutteridge Point', '46-(387)499-9367', 'gshovel76@boston.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (260, 'Shana Guirardin', '80094 Schurz Street', '57-(241)295-5278', 'sguirardin77@hibu.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (261, 'Micki Van der Kruijs', '95271 Lakewood Alley', '98-(200)379-4327', 'mvan78@com.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (262, 'Forster Pugh', '754 Spaight Center', '507-(639)421-8748', 'fpugh79@example.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (263, 'Graeme Santoro', '943 Hudson Pass', '66-(192)595-3621', 'gsantoro7a@spotify.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (264, 'Solomon Fernant', '0 Prairie Rose Drive', '81-(849)172-3710', 'sfernant7b@squarespace.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (265, 'Jennie Dumingo', '1 Sherman Terrace', '63-(316)703-4394', 'jdumingo7c@phoca.cz', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (266, 'Bryant Buffey', '52182 Pierstorff Place', '86-(321)725-7238', 'bbuffey7d@hatena.ne.jp', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (267, 'Amelie Balcombe', '9 Heffernan Crossing', '1-(699)618-4317', 'abalcombe7e@example.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (268, 'Roi Dimitriou', '876 Wayridge Circle', '256-(549)132-4465', 'rdimitriou7f@weather.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (269, 'Berne Beedham', '2291 Goodland Street', '86-(655)947-1310', 'bbeedham7g@biblegateway.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (270, 'Vanya Apps', '0517 Marcy Center', '237-(375)713-9973', 'vapps7h@loc.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (271, 'Bibi MacGorrie', '80 Kim Plaza', '970-(699)411-6236', 'bmacgorrie7i@cmu.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (272, 'Jen Stenson', '33938 Mendota Avenue', '86-(962)604-0799', 'jstenson7j@tuttocitta.it', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (273, 'Tatum Hatz', '40232 Vernon Park', '850-(435)491-2632', 'thatz7k@amazon.co.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (274, 'Jeanna Bernth', '5 Alpine Crossing', '595-(905)553-8961', 'jbernth7l@harvard.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (275, 'Deeyn Vidineev', '3211 Lakewood Gardens Crossing', '7-(506)688-2834', 'dvidineev7m@shareasale.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (276, 'Kessiah Anselm', '1242 Fordem Street', '27-(250)194-1109', 'kanselm7n@google.es', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (277, 'Vivie Manis', '7411 Oxford Road', '62-(625)542-5801', 'vmanis7o@narod.ru', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (278, 'Selie Sowter', '15 Bartillon Lane', '7-(503)504-5024', 'ssowter7p@is.gd', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (279, 'Toddie Plessing', '6 Ramsey Pass', '86-(819)876-4378', 'tplessing7q@arizona.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (280, 'Myca Sibun', '53 Texas Point', '98-(323)423-6628', 'msibun7r@nih.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (281, 'Nert Been', '61 Clove Park', '63-(835)440-3620', 'nbeen7s@hugedomains.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (282, 'Min Strewthers', '7 Truax Crossing', '86-(680)104-1434', 'mstrewthers7t@whitehouse.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (283, 'Bent Kilgrove', '13027 Burning Wood Alley', '1-(361)210-4584', 'bkilgrove7u@parallels.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (284, 'Belvia Ciani', '36 Pearson Avenue', '62-(229)953-2545', 'bciani7v@joomla.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (285, 'Jolynn Mallia', '21581 Porter Lane', '86-(575)740-5874', 'jmallia7w@cbslocal.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (286, 'Barnaby Gilson', '02634 West Avenue', '1-(183)483-2563', 'bgilson7x@geocities.jp', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (287, 'Catlin Polet', '19748 Di Loreto Street', '63-(891)430-8343', 'cpolet7y@cisco.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (288, 'Heddie Berrow', '5 Londonderry Court', '82-(923)731-0281', 'hberrow7z@redcross.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (289, 'Arther Terese', '081 Upham Road', '86-(589)846-2631', 'aterese80@comcast.net', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (290, 'Oona Footer', '459 Mitchell Junction', '48-(837)790-5652', 'ofooter81@europa.eu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (291, 'Brand Glinde', '077 Manitowish Road', '385-(259)861-5860', 'bglinde82@diigo.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (292, 'Josy Kolyagin', '74679 Cody Terrace', '7-(635)488-1527', 'jkolyagin83@techcrunch.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (293, 'Wandie Geddes', '8611 Tony Park', '967-(340)206-6342', 'wgeddes84@devhub.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (294, 'Chic Niese', '8874 Rieder Court', '86-(791)998-2711', 'cniese85@opensource.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (295, 'Ian Tippings', '1604 Iowa Center', '1-(214)938-5712', 'itippings86@studiopress.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (296, 'Troy Yole', '95 Lotheville Place', '86-(685)291-6666', 'tyole87@dmoz.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (297, 'Konstantin Catterson', '11 Carpenter Lane', '216-(202)289-5907', 'kcatterson88@yahoo.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (298, 'Elvin Boas', '52524 Moulton Court', '977-(635)558-9109', 'eboas89@goo.ne.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (299, 'Maisey Readwing', '1 Loftsgordon Trail', '51-(241)193-7150', 'mreadwing8a@trellian.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (300, 'Jeanette Powers', '92477 Novick Lane', '31-(977)936-0243', 'jpowers8b@adobe.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (301, 'Annalise Woodthorpe', '40360 Bay Lane', '86-(484)812-1504', 'awoodthorpe8c@nbcnews.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (302, 'Mady Cutcliffe', '94 Eliot Plaza', '351-(175)366-6168', 'mcutcliffe8d@seattletimes.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (303, 'Nikolaos Bosley', '075 Springs Terrace', '63-(416)236-9979', 'nbosley8e@nationalgeographic.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (304, 'Marilee Harberer', '23 Cordelia Terrace', '504-(464)326-5619', 'mharberer8f@archive.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (305, 'Kaiser Naire', '2 Kenwood Junction', '351-(356)204-0015', 'knaire8g@who.int', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (306, 'Georgie Vsanelli', '2 Kropf Park', '381-(553)964-1256', 'gvsanelli8h@ustream.tv', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (307, 'Merilee Olyff', '349 Continental Trail', '86-(917)482-7342', 'molyff8i@google.it', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (308, 'Walden Luney', '552 Pond Alley', '86-(117)156-4999', 'wluney8j@infoseek.co.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (309, 'Sophey St Leger', '287 Corscot Way', '33-(970)493-1221', 'sst8k@yelp.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (310, 'Darsey Greenall', '8838 Novick Center', '86-(729)550-2859', 'dgreenall8l@ihg.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (311, 'Beatrisa Moyles', '89942 Dahle Avenue', '47-(867)401-8478', 'bmoyles8m@webeden.co.uk', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (312, 'Ava Radke', '3759 Dakota Alley', '63-(341)508-8713', 'aradke8n@simplemachines.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (313, 'Gail McKerley', '5 Elka Place', '51-(420)891-9748', 'gmckerley8o@sciencedirect.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (314, 'Junia Kix', '76 Monterey Park', '63-(930)306-1272', 'jkix8p@purevolume.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (315, 'Hayyim Hathorn', '613 Nova Road', '86-(666)420-1334', 'hhathorn8q@dailymail.co.uk', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (316, 'Viole Mc Andrew', '73 Hermina Drive', '62-(766)433-3326', 'vmc8r@csmonitor.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (317, 'Cori MacAndie', '47 Redwing Street', '7-(494)777-2720', 'cmacandie8s@plala.or.jp', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (318, 'Justine Vanetti', '20103 Warner Place', '1-(636)638-4614', 'jvanetti8t@skyrock.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (319, 'Klara Burgett', '098 Union Way', '86-(485)488-7963', 'kburgett8u@cornell.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (320, 'Maximilianus O''Kinedy', '69 Carberry Park', '86-(760)781-3914', 'mokinedy8v@geocities.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (321, 'Karyn Abeau', '5 Glacier Hill Court', '1-(290)172-0895', 'kabeau8w@edublogs.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (322, 'Joy Nani', '38 Sachtjen Junction', '81-(365)185-5673', 'jnani8x@joomla.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (323, 'Blake Pakes', '6759 Crescent Oaks Pass', '30-(755)292-8610', 'bpakes8y@hibu.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (324, 'Dalton Ingerson', '9620 Oriole Parkway', '86-(795)898-7658', 'dingerson8z@examiner.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (325, 'Zedekiah Passo', '8162 Esker Hill', '46-(199)968-0534', 'zpasso90@goodreads.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (326, 'Julee Chaloner', '63 Muir Street', '375-(836)534-2512', 'jchaloner91@gov.uk', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (327, 'Ramsay Andrat', '2 Graceland Circle', '46-(566)971-3654', 'randrat92@acquirethisname.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (328, 'Angelico Friett', '2826 Mosinee Court', '57-(115)332-4785', 'afriett93@issuu.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (329, 'Doti Onion', '9642 Green Hill', '63-(251)759-5040', 'donion94@pinterest.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (330, 'Kit Moyles', '25 Banding Circle', '84-(415)972-6868', 'kmoyles95@domainmarket.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (331, 'Jacqui Cushelly', '3 Fairfield Pass', '62-(449)212-6421', 'jcushelly96@storify.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (332, 'Kat McConigal', '41 Monterey Trail', '62-(838)960-7488', 'kmcconigal97@archive.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (333, 'Barnabe Collison', '350 Ohio Point', '86-(773)585-9314', 'bcollison98@xrea.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (334, 'Hillard Campsall', '32213 Badeau Plaza', '33-(524)410-6911', 'hcampsall99@51.la', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (335, 'Kylen Celle', '40199 Wayridge Center', '46-(514)917-8355', 'kcelle9a@netscape.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (336, 'Abbe Le Page', '72472 Hintze Trail', '48-(749)913-8949', 'ale9b@archive.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (337, 'Raychel Filtness', '7 Nova Terrace', '86-(823)301-4125', 'rfiltness9c@wikimedia.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (338, 'Filippo Plante', '578 Debra Pass', '86-(652)146-2300', 'fplante9d@51.la', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (339, 'Shadow Ziemecki', '7099 Sutherland Drive', '86-(172)270-0735', 'sziemecki9e@people.com.cn', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (340, 'Sully Ogilby', '5 Ronald Regan Junction', '231-(664)868-4431', 'sogilby9f@umn.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (341, 'Joan Kermitt', '138 Tennyson Place', '1-(208)214-9290', 'jkermitt9g@theguardian.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (342, 'Linnet Spellward', '022 Brentwood Lane', '86-(750)592-5218', 'lspellward9h@mayoclinic.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (343, 'Murray Bunch', '5 Manufacturers Drive', '63-(274)550-2585', 'mbunch9i@simplemachines.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (344, 'Aurea Gerry', '422 Mifflin Trail', '86-(929)999-7429', 'agerry9j@tripod.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (345, 'Boony Castanyer', '65990 Anthes Road', '62-(333)496-0391', 'bcastanyer9k@yandex.ru', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (346, 'Pascal Josofovitz', '8669 Portage Park', '64-(343)616-3477', 'pjosofovitz9l@loc.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (347, 'Arlene Wilcott', '6698 American Ash Trail', '86-(951)898-7017', 'awilcott9m@skyrock.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (348, 'Cynthea Olenin', '3 Buena Vista Park', '7-(239)867-5981', 'colenin9n@de.vu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (349, 'Brose Hardey', '219 Forest Dale Crossing', '55-(526)211-0061', 'bhardey9o@cbc.ca', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (350, 'Perkin Tyhurst', '044 Hovde Court', '86-(800)397-9471', 'ptyhurst9p@dot.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (351, 'Tomi Bridel', '86 Gale Place', '86-(846)362-1997', 'tbridel9q@newyorker.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (352, 'Linn Lyvon', '20 Blackbird Terrace', '52-(755)992-0090', 'llyvon9r@sbwire.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (353, 'Melinda Beeby', '106 Anhalt Street', '62-(336)669-0002', 'mbeeby9s@dion.ne.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (354, 'Jonell Figgs', '22 Northridge Center', '57-(491)273-7599', 'jfiggs9t@indiatimes.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (355, 'Ferrel Gilders', '872 Bayside Center', '353-(414)331-0867', 'fgilders9u@mozilla.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (356, 'Ethelbert Burlay', '11976 Oak Valley Avenue', '86-(805)516-1256', 'eburlay9v@ow.ly', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (357, 'Kikelia Smitten', '70744 Moland Avenue', '51-(297)586-3238', 'ksmitten9w@oaic.gov.au', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (358, 'Ban Ryburn', '82078 Forster Crossing', '355-(876)273-8848', 'bryburn9x@zdnet.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (359, 'Isadora Pawelke', '4371 Di Loreto Parkway', '62-(101)847-5080', 'ipawelke9y@europa.eu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (360, 'Constance MacAllan', '745 Shelley Alley', '352-(353)811-8139', 'cmacallan9z@si.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (361, 'Cassi Stratiff', '164 Thompson Road', '33-(656)498-9991', 'cstratiffa0@weibo.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (362, 'Charlean Shinefield', '5 Sutteridge Alley', '31-(906)599-4912', 'cshinefielda1@nbcnews.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (363, 'Jarred Cabrera', '372 Sunfield Hill', '261-(991)379-2321', 'jcabreraa2@gnu.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (364, 'Walker Pena', '3805 Declaration Way', '63-(497)134-8688', 'wpenaa3@bing.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (365, 'Zondra Lympenie', '41 Oak Valley Plaza', '62-(865)370-6633', 'zlympeniea4@dmoz.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (366, 'Jaclyn Merlin', '1 Pankratz Road', '351-(976)502-9030', 'jmerlina5@discuz.net', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (367, 'Alisander Sudy', '7365 Burning Wood Plaza', '55-(457)653-2072', 'asudya6@phpbb.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (368, 'Lissa Pepin', '7280 Fisk Court', '55-(116)903-9506', 'lpepina7@ocn.ne.jp', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (369, 'Margette Huyche', '75864 Express Circle', '234-(703)560-6179', 'mhuychea8@unc.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (370, 'Milka Rasor', '63 Bowman Place', '82-(950)314-2472', 'mrasora9@sogou.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (371, 'Ivonne Bushby', '60678 Walton Crossing', '506-(272)712-9629', 'ibushbyaa@friendfeed.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (372, 'Patty Ponder', '83 Caliangt Lane', '48-(564)139-8558', 'pponderab@archive.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (373, 'Morgana Mantripp', '6 South Hill', '242-(182)320-8187', 'mmantrippac@skype.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (374, 'Mauricio Kubin', '01 South Way', '86-(604)571-0883', 'mkubinad@pbs.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (375, 'Dido Gaythorpe', '3067 Brentwood Crossing', '62-(254)146-5619', 'dgaythorpeae@shinystat.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (376, 'Rosalie Farr', '0331 Hudson Street', '86-(902)257-6934', 'rfarraf@fastcompany.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (377, 'Bambie Safhill', '2511 Miller Court', '351-(295)434-3491', 'bsafhillag@springer.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (378, 'Nigel Aslott', '8 Grover Way', '504-(928)868-6132', 'naslottah@booking.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (379, 'Crosby Moffatt', '471 Mayfield Road', '63-(181)858-0894', 'cmoffattai@guardian.co.uk', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (380, 'Carley Helkin', '4 Carey Plaza', '62-(891)925-5057', 'chelkinaj@umich.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (381, 'Babs Brabant', '18 Express Way', '30-(914)108-2958', 'bbrabantak@networksolutions.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (382, 'Berton Mitchiner', '97 Westridge Place', '27-(476)902-7337', 'bmitchineral@google.com.br', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (383, 'Wylma Davidovitch', '32118 Dawn Plaza', '33-(981)113-9960', 'wdavidovitcham@eepurl.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (384, 'Lamar Baly', '7884 Oriole Pass', '86-(124)948-2611', 'lbalyan@newyorker.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (385, 'Maye Jutson', '5633 Dottie Lane', '62-(276)139-2039', 'mjutsonao@usa.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (386, 'Emeline Peabody', '410 Rockefeller Circle', '998-(237)331-0915', 'epeabodyap@imgur.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (387, 'Marlin Aphale', '75 Straubel Place', '46-(769)872-3353', 'maphaleaq@sfgate.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (388, 'Doro Anscott', '39 Wayridge Trail', '86-(769)404-6824', 'danscottar@squarespace.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (389, 'Lexine Tatershall', '449 Gerald Trail', '380-(997)138-5064', 'ltatershallas@wix.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (390, 'Ricoriki Vedenyakin', '14506 Toban Terrace', '86-(228)105-7843', 'rvedenyakinat@creativecommons.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (391, 'Mab Knappen', '9402 Del Sol Parkway', '358-(101)162-8725', 'mknappenau@163.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (392, 'Nert Yegorchenkov', '8757 Fremont Plaza', '86-(260)294-3786', 'nyegorchenkovav@ft.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (393, 'Bevvy Morales', '78402 East Terrace', '62-(816)770-1455', 'bmoralesaw@google.com.br', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (394, 'Pattin Rubke', '1 Tennyson Alley', '46-(122)698-2862', 'prubkeax@hhs.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (395, 'Margery Stanlock', '247 Morningstar Center', '27-(730)551-8907', 'mstanlockay@europa.eu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (396, 'Mohammed Gollin', '42455 Monterey Park', '7-(127)999-0785', 'mgollinaz@ustream.tv', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (397, 'Putnem Caban', '14 Hoepker Plaza', '595-(139)724-2451', 'pcabanb0@patch.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (398, 'Aliza Wyvill', '01446 6th Parkway', '86-(873)855-9620', 'awyvillb1@youku.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (399, 'Gaylor Gerling', '499 Crest Line Terrace', '62-(892)942-9281', 'ggerlingb2@newyorker.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (400, 'Jennette Stihl', '73098 Duke Parkway', '7-(339)409-8964', 'jstihlb3@amazon.de', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (401, 'Peggy Adcock', '0723 Luster Road', '54-(335)392-7180', 'padcockb4@samsung.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (402, 'Cecilius Priestland', '4 Blackbird Plaza', '380-(755)732-4141', 'cpriestlandb5@businessweek.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (403, 'Hyacinth Wealthall', '1794 Red Cloud Crossing', '62-(885)956-6097', 'hwealthallb6@4shared.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (404, 'Kora Merchant', '3922 Onsgard Trail', '1-(570)455-9519', 'kmerchantb7@topsy.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (405, 'Bellanca Tremblay', '7 Grover Center', '86-(210)762-0410', 'btremblayb8@nytimes.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (406, 'Craggie Bellingham', '20 Fordem Way', '53-(532)758-7908', 'cbellinghamb9@sakura.ne.jp', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (407, 'Erin Eastope', '63493 Blue Bill Park Point', '976-(452)389-5630', 'eeastopeba@cyberchimps.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (408, 'Dorine Szymonowicz', '220 Walton Lane', '63-(147)146-9950', 'dszymonowiczbb@de.vu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (409, 'Cherida Haslum', '5241 Pierstorff Street', '64-(461)277-9809', 'chaslumbc@squarespace.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (410, 'Marve Oller', '85 Dapin Road', '262-(362)834-1940', 'mollerbd@soup.io', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (411, 'Teena Domnick', '7835 Express Road', '63-(339)376-5092', 'tdomnickbe@trellian.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (412, 'Claudette Betje', '9 Union Avenue', '46-(114)314-1226', 'cbetjebf@slideshare.net', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (413, 'Jolie Dawtre', '303 Heffernan Street', '86-(595)709-9816', 'jdawtrebg@fastcompany.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (414, 'Elysha Dalley', '604 Eliot Alley', '254-(695)574-4119', 'edalleybh@chicagotribune.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (415, 'Sean Spinelli', '387 Bartillon Avenue', '62-(995)561-5339', 'sspinellibi@goo.gl', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (416, 'Vinnie Budgen', '054 Fisk Center', '54-(377)494-0367', 'vbudgenbj@indiegogo.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (417, 'Theodosia Foxton', '98990 Prentice Drive', '62-(292)488-0239', 'tfoxtonbk@goo.gl', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (418, 'Rosamond Drewes', '30127 7th Road', '46-(228)250-9355', 'rdrewesbl@hatena.ne.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (419, 'Goldina Flowerdew', '29 Canary Street', '62-(151)715-2297', 'gflowerdewbm@macromedia.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (420, 'Rosana Sive', '33841 Bashford Park', '48-(260)123-7078', 'rsivebn@g.co', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (421, 'Rosemary Chicco', '42 Brentwood Park', '34-(738)549-7093', 'rchiccobo@yolasite.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (422, 'Cyndia Leming', '3992 Ilene Alley', '389-(183)724-5139', 'clemingbp@drupal.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (423, 'Tan Ricardet', '883 John Wall Court', '63-(872)961-6038', 'tricardetbq@desdev.cn', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (424, 'Rodolphe Seligson', '102 Golf View Terrace', '62-(434)247-1759', 'rseligsonbr@amazon.co.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (425, 'Corette Gwinn', '8 3rd Avenue', '7-(358)323-9886', 'cgwinnbs@drupal.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (426, 'Joela Patriskson', '8405 Memorial Center', '62-(519)519-8662', 'jpatrisksonbt@vimeo.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (427, 'Oneida Pharrow', '57471 Mosinee Junction', '55-(846)933-5434', 'opharrowbu@ucoz.ru', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (428, 'Rance Le Strange', '38731 Service Park', '92-(400)763-7530', 'rlebv@nps.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (429, 'Iolanthe Ordelt', '542 Ryan Hill', '1-(178)110-2273', 'iordeltbw@dailymail.co.uk', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (430, 'Rob Giroldo', '261 Bartillon Lane', '850-(763)267-0038', 'rgiroldobx@altervista.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (431, 'Annette Gartery', '542 Waywood Way', '7-(175)955-8732', 'agarteryby@blogs.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (432, 'Emmalynne Putman', '10 Pleasure Parkway', '227-(887)335-2359', 'eputmanbz@slate.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (433, 'Carlie Dunckley', '7553 Transport Terrace', '57-(459)502-1900', 'cdunckleyc0@last.fm', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (434, 'Mar Flatte', '6 Calypso Park', '81-(848)205-8434', 'mflattec1@gravatar.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (435, 'Thatcher Eagan', '21 Village Plaza', '86-(631)860-8451', 'teaganc2@nymag.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (436, 'Itch Boyfield', '16 Stang Court', '598-(571)647-1291', 'iboyfieldc3@nifty.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (437, 'Krispin Michelin', '37 Eagan Road', '46-(148)629-6557', 'kmichelinc4@unicef.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (438, 'Sammy McGarrity', '4 Monica Park', '371-(164)628-5017', 'smcgarrityc5@unicef.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (439, 'Em Guittet', '6854 Forest Dale Parkway', '46-(118)774-1961', 'eguittetc6@engadget.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (440, 'Donia Golling', '726 Onsgard Hill', '86-(297)647-4635', 'dgollingc7@flavors.me', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (441, 'Carry Lohering', '03672 Tennyson Park', '228-(497)372-1533', 'cloheringc8@nasa.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (442, 'Tracie Larby', '28972 Kennedy Parkway', '216-(965)416-6014', 'tlarbyc9@hp.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (443, 'Artemas Caple', '39 Dottie Alley', '86-(112)273-6859', 'acapleca@china.com.cn', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (444, 'Mab Livock', '1 Sullivan Point', '7-(449)952-0051', 'mlivockcb@state.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (445, 'Leontine Witherup', '812 Waubesa Court', '1-(442)555-1713', 'lwitherupcc@w3.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (446, 'Tressa Kingham', '5 Lyons Terrace', '86-(645)751-7033', 'tkinghamcd@reverbnation.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (447, 'Doria Wormstone', '88739 Coolidge Terrace', '63-(187)840-2046', 'dwormstonece@noaa.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (448, 'Birdie Margiotta', '73597 Declaration Circle', '1-(225)108-6223', 'bmargiottacf@pinterest.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (449, 'Orazio Spini', '99 Judy Pass', '48-(802)526-6771', 'ospinicg@gov.uk', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (450, 'Sally Rayner', '9892 Eastlawn Way', '57-(360)295-2555', 'sraynerch@mediafire.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (451, 'Thurstan Bannister', '323 Graedel Drive', '57-(690)858-5934', 'tbannisterci@unc.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (452, 'Tremaine Milella', '70 Dexter Parkway', '62-(275)825-1056', 'tmilellacj@salon.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (453, 'Jorie Adamou', '63 Mallard Avenue', '420-(483)566-2114', 'jadamouck@discovery.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (454, 'Thorin Lampe', '4570 Laurel Terrace', '62-(584)881-8353', 'tlampecl@psu.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (455, 'Chadd Chessor', '8 Packers Place', '84-(835)545-8403', 'cchessorcm@networkadvertising.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (456, 'Dyanna Ebbotts', '1 Shelley Alley', '359-(765)668-1745', 'debbottscn@goo.gl', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (457, 'Alexio Anderson', '69957 Moland Way', '86-(408)766-1331', 'aandersonco@list-manage.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (458, 'Jed Runsey', '449 Kim Circle', '62-(593)259-1325', 'jrunseycp@newsvine.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (459, 'Madlen Goodrich', '04 Darwin Alley', '420-(742)696-3574', 'mgoodrichcq@about.me', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (460, 'Levey Bowdon', '17177 Porter Court', '598-(290)268-4170', 'lbowdoncr@cnet.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (461, 'Maryellen Stowell', '6882 Buell Park', '63-(463)212-0839', 'mstowellcs@google.co.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (462, 'Gilligan Scramage', '91518 Elgar Place', '81-(141)519-5231', 'gscramagect@plala.or.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (463, 'Tabbatha Whether', '539 Bartillon Junction', '503-(958)596-2769', 'twhethercu@drupal.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (464, 'Gun Dixcey', '7097 Harper Hill', '86-(469)702-1018', 'gdixceycv@noaa.gov', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (465, 'Priscilla O''Mullally', '4 Artisan Point', '55-(878)551-9185', 'pomullallycw@vistaprint.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (466, 'Patricio Steutly', '9 Blaine Point', '33-(226)628-1898', 'psteutlycx@ifeng.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (467, 'Omar Prothero', '54 Scott Plaza', '62-(539)486-8250', 'oprotherocy@google.com.hk', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (468, 'Trix Rime', '940 Florence Court', '420-(899)408-0216', 'trimecz@odnoklassniki.ru', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (469, 'Berkeley Porte', '20 International Pass', '86-(386)811-1369', 'bported0@go.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (470, 'Chrisse Oliveti', '8 Lindbergh Alley', '86-(371)904-3388', 'colivetid1@sbwire.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (471, 'Noella Jeayes', '66 Schiller Hill', '595-(346)402-1570', 'njeayesd2@auda.org.au', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (472, 'Basia Hunn', '7525 Village Junction', '1-(800)429-3856', 'bhunnd3@woothemes.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (473, 'Kalle Coulthard', '8 Summer Ridge Way', '234-(852)568-0139', 'kcoulthardd4@4shared.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (474, 'Freida Grenfell', '30 Dunning Pass', '62-(994)539-0148', 'fgrenfelld5@columbia.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (475, 'Valry Magowan', '097 Starling Place', '66-(581)379-6384', 'vmagowand6@arstechnica.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (476, 'Timofei Scading', '6 Roth Junction', '30-(812)970-1572', 'tscadingd7@imdb.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (477, 'Donielle Swatten', '43050 Killdeer Court', '963-(107)477-6868', 'dswattend8@bbb.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (478, 'Kinny Viscovi', '1 Florence Place', '58-(131)318-0470', 'kviscovid9@springer.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (479, 'Bastian Fairburne', '2 Gerald Place', '51-(973)265-6633', 'bfairburneda@jugem.jp', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (480, 'Dominik Withams', '8733 Texas Center', '81-(852)591-9856', 'dwithamsdb@google.es', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (481, 'Jenn Jurczik', '18 American Point', '7-(743)538-1004', 'jjurczikdc@symantec.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (482, 'Courtenay Bygott', '229 Tennyson Court', '385-(908)948-7124', 'cbygottdd@vimeo.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (483, 'Andie Norkett', '2624 Old Shore Court', '62-(136)478-4347', 'anorkettde@slate.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (484, 'Lisbeth Puden', '53 Corry Point', '86-(813)541-8450', 'lpudendf@webnode.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (485, 'West Gilhooley', '412 Loeprich Road', '81-(369)111-1952', 'wgilhooleydg@zdnet.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (486, 'Ag Fossitt', '8 Hintze Road', '48-(112)697-4337', 'afossittdh@tripod.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (487, 'Stevie Swatradge', '8 Badeau Court', '55-(202)899-2257', 'sswatradgedi@bbc.co.uk', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (488, 'Dulce Minett', '2 Gerald Trail', '62-(104)506-2011', 'dminettdj@amazon.de', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (489, 'Clayborn Freed', '4 Tennessee Terrace', '967-(108)701-0300', 'cfreeddk@google.it', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (490, 'Teodor Rennix', '869 Mockingbird Parkway', '251-(420)157-3082', 'trennixdl@studiopress.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (491, 'Cathleen Laurentin', '06922 Sachs Crossing', '66-(174)745-4105', 'claurentindm@slideshare.net', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (492, 'Rora Benneyworth', '17448 Hallows Plaza', '7-(766)932-4280', 'rbenneyworthdn@goodreads.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (493, 'Garwood Atter', '08 Stang Court', '7-(393)409-1727', 'gatterdo@dailymail.co.uk', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (494, 'Gerhard Shelper', '53215 Novick Terrace', '31-(726)900-6433', 'gshelperdp@nytimes.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (495, 'Maud Dahlberg', '20 Bunting Drive', '30-(274)911-7508', 'mdahlbergdq@seattletimes.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (496, 'Meara Charity', '8592 Claremont Terrace', '92-(309)514-9379', 'mcharitydr@tripadvisor.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (497, 'Cosmo Salters', '8 Westridge Alley', '1-(475)746-3356', 'csaltersds@wix.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (498, 'Torrie Marcam', '2978 David Trail', '66-(709)644-7251', 'tmarcamdt@clickbank.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (499, 'Tiffany Vell', '4108 Granby Crossing', '86-(181)257-2604', 'tvelldu@xinhuanet.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (500, 'Tome Somerton', '68504 Sage Lane', '52-(909)858-9892', 'tsomertondv@netscape.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (501, 'Elysha Vennart', '13 Butternut Parkway', '7-(529)599-3289', 'evennartdw@sbwire.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (502, 'Silvain Gomez', '0 Bellgrove Point', '33-(471)648-6382', 'sgomezdx@mayoclinic.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (503, 'Sophie Deboick', '16623 Mariners Cove Road', '51-(588)431-7145', 'sdeboickdy@dailymotion.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (504, 'Linnea Mulder', '084 Bellgrove Plaza', '62-(998)922-5582', 'lmulderdz@hao123.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (505, 'Neddy Bunclark', '67 Mosinee Hill', '66-(153)791-7986', 'nbunclarke0@yolasite.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (506, 'Glynn Fallowes', '25841 Warrior Road', '84-(340)765-2888', 'gfallowese1@cbsnews.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (507, 'Delmer Reinard', '06 High Crossing Road', '86-(340)283-5226', 'dreinarde2@google.ru', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (508, 'Redford Gummory', '7 Stoughton Road', '420-(904)720-6119', 'rgummorye3@about.me', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (509, 'Tabbie Maccari', '96 Fuller Trail', '505-(373)418-2460', 'tmaccarie4@ebay.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (510, 'Marlo Tidgewell', '9510 Hayes Park', '48-(127)418-6539', 'mtidgewelle5@redcross.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (511, 'Eolanda Burnhard', '393 Loeprich Circle', '7-(102)681-3642', 'eburnharde6@google.co.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (512, 'Felita O''Bradain', '7498 Prairieview Pass', '48-(947)474-6350', 'fobradaine7@mashable.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (513, 'Annelise Hickeringill', '0 Scott Plaza', '62-(545)393-3017', 'ahickeringille8@dyndns.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (514, 'Dru Cainey', '728 Michigan Crossing', '48-(114)954-1028', 'dcaineye9@home.pl', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (515, 'Dori Chasmar', '7611 Judy Alley', '81-(538)519-9020', 'dchasmarea@cmu.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (516, 'Delbert Mulvy', '72083 Hagan Plaza', '7-(452)924-7050', 'dmulvyeb@livejournal.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (517, 'Kailey Walsham', '7 Elmside Lane', '81-(715)730-2245', 'kwalshamec@buzzfeed.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (518, 'Brittani Rubury', '12925 Hanover Crossing', '52-(296)237-9793', 'bruburyed@hud.gov', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (519, 'Griz Botwright', '81 Hansons Court', '223-(682)268-7198', 'gbotwrightee@google.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (520, 'Conney Puttan', '93 Toban Court', '55-(331)814-9263', 'cputtanef@vk.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (521, 'Aida Pottberry', '53 Scott Avenue', '62-(853)489-0031', 'apottberryeg@reference.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (522, 'Niles Bonfield', '5423 Algoma Junction', '63-(919)747-7580', 'nbonfieldeh@omniture.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (523, 'Cornall Winterbourne', '242 7th Drive', '33-(278)457-2470', 'cwinterbourneei@imdb.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (524, 'Caryn Skeath', '7 3rd Street', '86-(228)480-3936', 'cskeathej@webeden.co.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (525, 'Basil Swynfen', '269 Prairieview Alley', '7-(739)833-6171', 'bswynfenek@skyrock.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (526, 'Erma Seagrave', '6392 Oak Valley Avenue', '86-(838)306-3615', 'eseagraveel@fastcompany.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (527, 'Barr Turville', '4773 Springview Way', '46-(667)181-2650', 'bturvilleem@tripadvisor.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (528, 'Valli O''Gavin', '6689 Buell Parkway', '355-(535)688-3360', 'vogavinen@studiopress.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (529, 'Marshal Garnul', '03813 Maple Wood Trail', '33-(142)676-6055', 'mgarnuleo@yale.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (530, 'Stanislas Pods', '1427 Cascade Alley', '86-(936)925-1199', 'spodsep@purevolume.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (531, 'Laetitia Nickolls', '4 Spenser Circle', '54-(733)702-2626', 'lnickollseq@ehow.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (532, 'Desmond Lenchenko', '1 Drewry Road', '92-(288)728-7578', 'dlenchenkoer@symantec.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (533, 'Charline Scemp', '9 Bartelt Drive', '62-(391)765-5887', 'cscempes@tripadvisor.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (534, 'Artair Matussow', '82886 Crowley Way', '94-(378)387-7152', 'amatussowet@ebay.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (535, 'Mallissa Esterbrook', '55879 Goodland Court', '30-(259)350-4330', 'mesterbrookeu@unc.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (536, 'Ambrosius Webborn', '8 Iowa Place', '55-(110)513-2636', 'awebbornev@elegantthemes.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (537, 'Ruby Gomersall', '41037 Schurz Way', '420-(834)135-4320', 'rgomersallew@amazon.de', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (538, 'Alaine Foxworthy', '744 Ridgeview Plaza', '7-(626)824-2958', 'afoxworthyex@networksolutions.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (539, 'Ezequiel Ovitts', '21 Mockingbird Terrace', '7-(980)199-5907', 'eovittsey@ask.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (540, 'Bax Billanie', '7 Di Loreto Crossing', '62-(762)324-1055', 'bbillanieez@yale.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (541, 'Selene Vanner', '4 Prairie Rose Hill', '51-(354)380-3974', 'svannerf0@toplist.cz', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (542, 'Erl Simeonov', '2 Donald Way', '351-(142)669-3082', 'esimeonovf1@samsung.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (543, 'Rikki Thomasen', '66783 Red Cloud Trail', '351-(746)438-8527', 'rthomasenf2@addthis.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (544, 'Katuscha Patrie', '7833 Bunting Circle', '86-(866)527-2267', 'kpatrief3@smh.com.au', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (545, 'Jenny Hartzog', '38132 Emmet Point', '86-(905)332-8787', 'jhartzogf4@ucoz.ru', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (546, 'Tate Holsall', '362 Anderson Junction', '86-(527)964-1864', 'tholsallf5@statcounter.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (547, 'Annamaria Boughton', '80295 Acker Avenue', '359-(520)368-5004', 'aboughtonf6@wordpress.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (548, 'Rockey De Dei', '902 Algoma Center', '86-(556)578-3473', 'rdef7@salon.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (549, 'Wrennie Fenck', '86 Village Alley', '598-(121)163-3133', 'wfenckf8@technorati.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (550, 'Stephine Apfel', '50537 American Alley', '86-(869)702-6081', 'sapfelf9@google.pl', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (551, 'Yorgo Chadd', '64086 Clarendon Road', '62-(773)938-9201', 'ychaddfa@eepurl.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (552, 'Cass Collinge', '6034 Sauthoff Center', '62-(215)515-6455', 'ccollingefb@dell.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (553, 'Melisa Hadigate', '9622 Mariners Cove Point', '62-(299)715-6127', 'mhadigatefc@bbc.co.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (554, 'Lionel Phillott', '43851 Helena Parkway', '33-(732)854-1511', 'lphillottfd@shop-pro.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (555, 'Ruthy Rolfs', '7 Schurz Lane', '383-(428)151-7469', 'rrolfsfe@mac.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (556, 'Stephen Swanne', '036 Talmadge Street', '63-(693)128-7195', 'sswanneff@twitpic.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (557, 'Dav Glassopp', '61419 Upham Court', '62-(760)780-9033', 'dglassoppfg@apple.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (558, 'Ainslie Abell', '99976 Sachs Crossing', '51-(261)796-0672', 'aabellfh@de.vu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (559, 'Libbie Binley', '18309 Waubesa Trail', '81-(585)157-9524', 'lbinleyfi@nymag.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (560, 'Regina Elson', '3 Merry Trail', '57-(762)344-1492', 'relsonfj@ning.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (561, 'Keene Quig', '5 Everett Way', '63-(733)833-5464', 'kquigfk@google.pl', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (562, 'Flor Chrispin', '8744 Bluestem Drive', '380-(680)124-1276', 'fchrispinfl@ycombinator.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (563, 'Elyn Goley', '7 Bobwhite Court', '62-(164)286-0029', 'egoleyfm@disqus.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (564, 'Willard Taw', '6467 Shoshone Hill', '46-(394)484-6002', 'wtawfn@sogou.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (565, 'Ekaterina Capey', '8153 Superior Road', '62-(234)354-9239', 'ecapeyfo@example.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (566, 'Ado Frodsam', '3723 Tony Plaza', '261-(761)115-2669', 'afrodsamfp@java.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (567, 'Ula Clousley', '529 Northwestern Road', '374-(351)194-2224', 'uclousleyfq@economist.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (568, 'Pinchas Reuther', '434 Wayridge Trail', '7-(196)104-8075', 'preutherfr@go.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (569, 'Elvis Sawforde', '6 Bultman Junction', '1-(168)246-0247', 'esawfordefs@goo.ne.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (570, 'Gibby Pottinger', '805 Schiller Hill', '62-(391)773-9383', 'gpottingerft@theglobeandmail.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (571, 'Deirdre Lidierth', '65 Victoria Avenue', '86-(381)950-1717', 'dlidierthfu@elpais.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (572, 'Hedvige Sibley', '6 Anthes Terrace', '994-(872)827-5736', 'hsibleyfv@prweb.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (573, 'Barnabas Biddle', '104 Walton Center', '86-(370)537-3451', 'bbiddlefw@prnewswire.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (574, 'Vivianne Parks', '163 Monterey Junction', '86-(745)365-5188', 'vparksfx@photobucket.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (575, 'Rustin Pochin', '1699 Scofield Terrace', '33-(689)474-1229', 'rpochinfy@tmall.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (576, 'Enrico Petchey', '7 Park Meadow Place', '55-(777)501-1669', 'epetcheyfz@hao123.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (577, 'Cesar Baldung', '10 Old Shore Road', '86-(917)158-4148', 'cbaldungg0@usgs.gov', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (578, 'Emmalynn Peatt', '895 Onsgard Street', '234-(129)390-8228', 'epeattg1@sourceforge.net', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (579, 'Carole Kaaskooper', '8119 Kedzie Plaza', '66-(953)379-0599', 'ckaaskooperg2@zdnet.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (580, 'Ellswerth Kunat', '4153 Village Crossing', '7-(126)226-2720', 'ekunatg3@oakley.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (581, 'Nappy Moulsdale', '33105 Mallard Road', '509-(416)332-6310', 'nmoulsdaleg4@arizona.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (582, 'Gordie Grogor', '148 Spaight Place', '66-(301)400-6632', 'ggrogorg5@addtoany.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (583, 'Cad Connachan', '906 Badeau Place', '963-(655)728-5303', 'cconnachang6@geocities.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (584, 'Templeton Gurner', '2 Elgar Avenue', '502-(353)937-6449', 'tgurnerg7@amazon.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (585, 'Humfried Jocelyn', '4561 Buena Vista Parkway', '44-(448)584-3243', 'hjocelyng8@dot.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (586, 'Nicol Ablewhite', '0155 Rowland Point', '55-(988)390-2696', 'nablewhiteg9@cnet.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (587, 'Rob Rubens', '22481 Kennedy Trail', '86-(772)907-7350', 'rrubensga@ebay.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (588, 'Felipa Purselowe', '2884 Lyons Terrace', '212-(656)308-0800', 'fpurselowegb@cloudflare.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (589, 'Sharline Gillion', '4 Jenifer Junction', '351-(927)738-3229', 'sgilliongc@dell.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (590, 'Mei Decroix', '4174 Derek Plaza', '358-(299)747-4949', 'mdecroixgd@state.tx.us', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (591, 'Elfrida Broxap', '01656 Warner Parkway', '62-(416)798-6189', 'ebroxapge@tinyurl.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (592, 'Reine Dadley', '9 Longview Plaza', '351-(977)849-6169', 'rdadleygf@blogspot.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (593, 'Cassandry Simonson', '0 Brentwood Parkway', '86-(158)500-1510', 'csimonsongg@scientificamerican.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (594, 'Brear Pacheco', '6918 Fisk Junction', '7-(585)450-8195', 'bpachecogh@ow.ly', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (595, 'Ulrich Nortcliffe', '66 Beilfuss Hill', '86-(968)780-4891', 'unortcliffegi@deliciousdays.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (596, 'Steve Skeech', '90786 Carioca Way', '86-(856)338-1686', 'sskeechgj@about.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (597, 'Berkly De Blasiis', '7 Ryan Lane', '86-(593)381-0367', 'bdegk@shop-pro.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (598, 'Rodi MacKnight', '7 Welch Alley', '55-(605)989-6275', 'rmacknightgl@elegantthemes.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (599, 'Maisie Hillitt', '0926 Morrow Way', '52-(525)294-8452', 'mhillittgm@1688.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (600, 'Ricky Balcon', '336 Cody Park', '221-(461)941-3436', 'rbalcongn@bing.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (601, 'Antoni Boleyn', '40 Union Pass', '63-(974)485-4773', 'aboleyngo@histats.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (602, 'Guillema Lesper', '2 Sheridan Road', '57-(653)663-6003', 'glespergp@zdnet.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (603, 'Eldridge Yurikov', '24138 Thierer Pass', '63-(467)125-9656', 'eyurikovgq@de.vu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (604, 'Cirilo Beverage', '40081 Dawn Hill', '81-(810)173-7856', 'cbeveragegr@163.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (605, 'Kelwin Horley', '2 Monica Crossing', '265-(632)169-2217', 'khorleygs@addthis.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (606, 'Roldan Schirok', '2 Lindbergh Lane', '55-(877)420-1949', 'rschirokgt@wp.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (607, 'Christi Sagerson', '7 Carberry Parkway', '52-(972)474-6796', 'csagersongu@jigsy.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (608, 'Edgard Blackshaw', '6386 Corben Junction', '7-(128)766-8612', 'eblackshawgv@xrea.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (609, 'Alanah Meys', '2 Southridge Way', '86-(814)858-9552', 'ameysgw@twitter.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (610, 'Honor Gariff', '30 Maple Way', '675-(455)357-0583', 'hgariffgx@etsy.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (611, 'Adrian Cristobal', '264 Gulseth Lane', '86-(228)845-1604', 'acristobalgy@privacy.gov.au', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (612, 'Les Klamman', '6 Maywood Circle', '62-(888)578-4641', 'lklammangz@seesaa.net', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (613, 'Andrew Piscotti', '965 Kedzie Junction', '55-(124)964-7245', 'apiscottih0@4shared.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (614, 'Bethina Fourcade', '7 Kinsman Crossing', '66-(397)867-5914', 'bfourcadeh1@uol.com.br', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (615, 'Lennard Freschini', '3177 Elgar Crossing', '62-(856)599-0134', 'lfreschinih2@liveinternet.ru', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (616, 'Mariska McMenamie', '3613 Dryden Avenue', '20-(383)804-9990', 'mmcmenamieh3@ca.gov', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (617, 'Glynis Naldrett', '79980 Fuller Alley', '55-(106)912-8313', 'gnaldretth4@amazon.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (618, 'Constantia Riach', '7 Chive Point', '57-(906)818-2078', 'criachh5@about.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (619, 'Dyann Cullingford', '7 Manitowish Place', '51-(160)710-6781', 'dcullingfordh6@rambler.ru', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (620, 'Eddie Swynfen', '1276 Birchwood Park', '51-(693)435-9313', 'eswynfenh7@indiatimes.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (621, 'Phineas Heppner', '4053 Portage Avenue', '502-(864)215-7941', 'pheppnerh8@tumblr.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (622, 'Queenie Hedgecock', '82437 Kedzie Street', '963-(854)839-5146', 'qhedgecockh9@google.ca', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (623, 'Vera Philippard', '6 West Circle', '383-(844)833-0615', 'vphilippardha@mozilla.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (624, 'Emelda Duprey', '27144 Larry Avenue', '504-(746)817-2724', 'edupreyhb@yellowpages.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (625, 'Ketti Parker', '932 Hudson Plaza', '30-(150)723-1354', 'kparkerhc@reference.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (626, 'Niel Gallego', '285 Birchwood Lane', '62-(753)801-8544', 'ngallegohd@deliciousdays.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (627, 'Gard Clist', '7 East Hill', '81-(946)112-4643', 'gclisthe@issuu.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (628, 'Vergil Soame', '843 Elgar Place', '33-(566)308-0548', 'vsoamehf@omniture.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (629, 'Mort Shayler', '22826 Pleasure Road', '7-(857)451-0706', 'mshaylerhg@histats.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (630, 'Rosaleen Pook', '87 Grover Center', '63-(821)349-1390', 'rpookhh@artisteer.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (631, 'Emalee Norvell', '52810 American Street', '56-(298)804-4275', 'enorvellhi@google.nl', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (632, 'Sammie Geockle', '02712 Maple Wood Park', '62-(631)831-9390', 'sgeocklehj@fotki.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (633, 'Francisco Hrishanok', '74200 Hanson Plaza', '62-(733)388-7291', 'fhrishanokhk@goo.gl', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (634, 'Pennie Bezant', '7 Rowland Terrace', '30-(573)749-1598', 'pbezanthl@cbslocal.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (635, 'Katrinka Jobbing', '05325 Donald Point', '1-(120)501-3136', 'kjobbinghm@soundcloud.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (636, 'Tania Candwell', '2 Evergreen Road', '504-(378)177-9130', 'tcandwellhn@archive.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (637, 'Starlin Learmount', '166 5th Avenue', '86-(442)272-2193', 'slearmountho@ameblo.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (638, 'Berkley Sanchis', '14482 Packers Street', '64-(812)200-1454', 'bsanchishp@uiuc.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (639, 'Desdemona Siviour', '918 Morrow Pass', '52-(636)734-5878', 'dsiviourhq@ebay.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (640, 'Brigida Paolotto', '48 Dexter Place', '63-(987)196-6948', 'bpaolottohr@apple.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (641, 'Lenka Jack', '768 Nova Place', '850-(530)958-7451', 'ljackhs@edublogs.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (642, 'Demetre Grahamslaw', '2602 Grim Trail', '55-(998)677-7930', 'dgrahamslawht@opera.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (643, 'Wheeler Emtage', '16 Carey Alley', '86-(804)265-6214', 'wemtagehu@cmu.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (644, 'Delainey Tribell', '91 Stoughton Place', '46-(238)907-9949', 'dtribellhv@netlog.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (645, 'Torrance Dourin', '6 Browning Hill', '358-(403)367-2726', 'tdourinhw@auda.org.au', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (646, 'Aubrey Dominik', '52 Randy Plaza', '995-(475)399-8401', 'adominikhx@typepad.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (647, 'Verna Conn', '6439 Ludington Road', '86-(392)657-9655', 'vconnhy@google.de', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (648, 'Claudian Bruun', '435 Heath Road', '86-(609)808-9801', 'cbruunhz@adobe.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (649, 'Clareta Antoniades', '299 Moland Point', '51-(705)687-8985', 'cantoniadesi0@usatoday.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (650, 'Florina MacAne', '61095 Talmadge Road', '358-(220)351-4666', 'fmacanei1@comcast.net', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (651, 'Sophey McDougal', '636 Melby Trail', '504-(998)709-4365', 'smcdougali2@alibaba.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (652, 'Selinda Bernardon', '65963 Debra Avenue', '62-(279)864-9735', 'sbernardoni3@flickr.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (653, 'Tomkin Rubenfeld', '9 Schiller Plaza', '86-(783)667-1401', 'trubenfeldi4@earthlink.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (654, 'Dee Madoc-Jones', '078 Laurel Avenue', '46-(944)712-7640', 'dmadocjonesi5@youtube.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (655, 'Paxon Swaby', '2127 Muir Terrace', '62-(354)194-2597', 'pswabyi6@bluehost.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (656, 'Lita Reditt', '06496 Tennessee Way', '62-(506)241-5199', 'lreditti7@intel.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (657, 'Valerie Gulley', '26078 Express Circle', '57-(904)178-9727', 'vgulleyi8@godaddy.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (658, 'Burk Sleet', '1308 Lake View Park', '86-(168)890-0086', 'bsleeti9@patch.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (659, 'Gertie Restorick', '86980 7th Lane', '86-(504)884-9589', 'grestorickia@arizona.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (660, 'Meggy Colnett', '94985 Messerschmidt Place', '389-(337)930-5869', 'mcolnettib@dailymotion.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (661, 'Oliy Bissett', '25 Fairview Place', '81-(427)286-0466', 'obissettic@ebay.co.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (662, 'Josefina Newiss', '193 Thierer Terrace', '52-(261)756-6254', 'jnewissid@hibu.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (663, 'Gibby Rosoni', '0759 Ridge Oak Alley', '55-(807)212-3312', 'grosoniie@upenn.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (664, 'Chiquita Lukesch', '72 Rieder Lane', '81-(145)490-7075', 'clukeschif@example.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (665, 'Bradford Jewer', '8122 Center Junction', '54-(945)663-4630', 'bjewerig@sitemeter.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (666, 'Boonie Buttery', '9912 7th Court', '62-(268)297-5745', 'bbutteryih@china.com.cn', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (667, 'Noll Mougeot', '21888 Tony Way', '7-(230)535-1052', 'nmougeotii@google.de', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (668, 'Cosimo Jantzen', '95086 Briar Crest Junction', '66-(539)382-9814', 'cjantzenij@ucsd.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (669, 'Horatius McLaren', '9 Express Way', '86-(547)418-6303', 'hmclarenik@senate.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (670, 'Denny Hartright', '62938 Waubesa Crossing', '966-(999)983-6397', 'dhartrightil@issuu.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (671, 'Melisse Galero', '244 Ridgeview Pass', '7-(495)577-4487', 'mgaleroim@prnewswire.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (672, 'Rodolfo Menezes', '7 Sachs Hill', '86-(320)238-7776', 'rmenezesin@google.fr', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (673, 'Madalyn Davey', '03296 Nova Parkway', '63-(229)389-6532', 'mdaveyio@g.co', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (674, 'Rachael Ragbourne', '764 Eastlawn Way', '7-(280)900-1100', 'rragbourneip@diigo.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (675, 'Ileana Fairley', '3 Hagan Parkway', '506-(185)818-0858', 'ifairleyiq@constantcontact.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (676, 'Jayme Blasoni', '76377 Butterfield Crossing', '62-(431)195-9162', 'jblasoniir@youku.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (677, 'Angelita Adams', '80118 Hanson Alley', '86-(326)262-9617', 'aadamsis@lulu.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (678, 'Scot Camilletti', '233 Merry Hill', '351-(479)932-6400', 'scamillettiit@pen.io', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (679, 'Vonni Rallinshaw', '60211 Bartillon Parkway', '234-(803)723-2878', 'vrallinshawiu@biblegateway.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (680, 'Odette Devenport', '02 Jenna Circle', '66-(620)830-3953', 'odevenportiv@usgs.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (681, 'Isidore Peacocke', '1 Rigney Alley', '381-(254)254-1709', 'ipeacockeiw@marriott.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (682, 'Pate McHugh', '8648 Heath Street', '86-(758)982-1610', 'pmchughix@bbb.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (683, 'Goldia Bridgland', '4 Onsgard Way', '420-(953)209-1977', 'gbridglandiy@tiny.cc', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (684, 'Langston Robarts', '8 Schiller Street', '54-(739)965-4768', 'lrobartsiz@godaddy.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (685, 'Hurleigh Nangle', '9 Browning Court', '254-(805)351-4482', 'hnanglej0@free.fr', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (686, 'Baxy Ellif', '0272 Sunbrook Circle', '46-(884)414-4675', 'bellifj1@yelp.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (687, 'Ransell Fulmen', '684 Spohn Way', '86-(501)121-7406', 'rfulmenj2@skyrock.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (688, 'Charyl Murfill', '21 Del Mar Hill', '51-(122)787-2746', 'cmurfillj3@who.int', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (689, 'Aldin Pavlata', '187 Buena Vista Plaza', '62-(787)855-0372', 'apavlataj4@miitbeian.gov.cn', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (690, 'Sandi Davet', '13 Parkside Street', '54-(420)970-5303', 'sdavetj5@exblog.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (691, 'Cristen Jewsbury', '73 Continental Terrace', '46-(330)676-3038', 'cjewsburyj6@telegraph.co.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (692, 'Adrea Ennion', '6 Glendale Street', '33-(163)497-0974', 'aennionj7@smh.com.au', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (693, 'Bastian Godmer', '95 Valley Edge Street', '297-(844)681-4068', 'bgodmerj8@slashdot.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (694, 'Jaime Fost', '77226 Arapahoe Parkway', '86-(847)459-5524', 'jfostj9@blinklist.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (695, 'Pincus Shales', '8502 Gulseth Point', '252-(727)822-7250', 'pshalesja@slideshare.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (696, 'Ingaborg Merrywether', '800 Hintze Trail', '86-(368)847-9213', 'imerrywetherjb@g.co', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (697, 'Merilyn Mordanti', '91485 Prairie Rose Crossing', '62-(647)473-6785', 'mmordantijc@senate.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (698, 'Nikola Pesak', '07 North Way', '86-(630)510-8244', 'npesakjd@foxnews.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (699, 'Rouvin Windley', '4346 East Street', '358-(258)609-3017', 'rwindleyje@techcrunch.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (700, 'Ajay Poznanski', '4 Bay Place', '46-(762)700-4534', 'apoznanskijf@addtoany.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (701, 'April Clausen-Thue', '730 Fulton Place', '1-(451)968-7762', 'aclausenthuejg@elpais.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (702, 'Billie Philpault', '578 Elgar Circle', '66-(417)766-4599', 'bphilpaultjh@kickstarter.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (703, 'Guglielma Sproson', '399 Delaware Avenue', '62-(832)236-9829', 'gsprosonji@dot.gov', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (704, 'Auberta Mattersey', '4403 Bunting Avenue', '55-(304)803-2492', 'amatterseyjj@businessweek.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (705, 'Eli Block', '70585 Messerschmidt Alley', '20-(465)224-1638', 'eblockjk@fotki.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (706, 'Killy MacCoughen', '3997 Walton Street', '62-(969)897-2604', 'kmaccoughenjl@eventbrite.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (707, 'Linnet Anderton', '9533 Elgar Terrace', '55-(507)101-1434', 'landertonjm@123-reg.co.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (708, 'Benyamin Langstone', '47 Eagan Junction', '56-(212)331-8137', 'blangstonejn@foxnews.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (709, 'Wendi Geldard', '31037 Esch Trail', '62-(267)396-2627', 'wgeldardjo@google.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (710, 'Ellissa Germaine', '3993 Eggendart Circle', '66-(160)869-6429', 'egermainejp@pcworld.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (711, 'Gary Cory', '36346 Mccormick Crossing', '93-(331)329-1331', 'gcoryjq@seattletimes.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (712, 'Caressa Gilhooly', '28091 8th Point', '20-(920)412-2855', 'cgilhoolyjr@t-online.de', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (713, 'Dame Sambell', '069 Morrow Court', '86-(779)669-9361', 'dsambelljs@g.co', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (714, 'Roch Dorney', '89 Commercial Circle', '31-(565)585-9104', 'rdorneyjt@cmu.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (715, 'Heinrick Yerrall', '6 Old Gate Avenue', '81-(545)634-7237', 'hyerrallju@jimdo.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (716, 'Alick Feacham', '95 Fairfield Trail', '355-(976)759-3757', 'afeachamjv@miibeian.gov.cn', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (717, 'Denys Shadwick', '369 Almo Terrace', '63-(784)415-2456', 'dshadwickjw@engadget.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (718, 'Agatha Trobridge', '689 Mendota Pass', '225-(294)724-0952', 'atrobridgejx@dropbox.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (719, 'Jerry Wintersgill', '28 Main Lane', '251-(768)525-1885', 'jwintersgilljy@about.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (720, 'Mimi Worden', '0170 2nd Pass', '63-(378)774-6055', 'mwordenjz@live.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (721, 'Pansy Gimblett', '04386 Evergreen Place', '381-(607)819-1363', 'pgimblettk0@economist.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (722, 'Romain Collabine', '9219 Blackbird Center', '48-(331)678-7725', 'rcollabinek1@examiner.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (723, 'Gustave Rivalland', '46742 Harbort Pass', '54-(538)703-6009', 'grivallandk2@ustream.tv', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (724, 'Hadrian Yirrell', '79 Shasta Crossing', '856-(976)994-3466', 'hyirrellk3@time.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (725, 'Morrie Wayvill', '8 Pond Center', '63-(358)599-5406', 'mwayvillk4@rediff.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (726, 'Leshia Conry', '2387 Bowman Trail', '86-(789)643-5193', 'lconryk5@blogspot.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (727, 'Chalmers Gelly', '75 Di Loreto Way', '62-(487)380-2461', 'cgellyk6@clickbank.net', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (728, 'Ophelia Cryer', '74072 Eagan Lane', '62-(429)567-6885', 'ocryerk7@cocolog-nifty.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (729, 'Iseabal Quenby', '815 Meadow Vale Pass', '381-(211)106-3370', 'iquenbyk8@cmu.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (730, 'Donall McFadyen', '3505 Fordem Circle', '249-(436)433-4536', 'dmcfadyenk9@elpais.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (731, 'Lester Lamplough', '1143 Johnson Trail', '62-(607)185-3022', 'llamploughka@shutterfly.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (732, 'Annecorinne Burbridge', '0 Onsgard Alley', '7-(440)304-8432', 'aburbridgekb@github.io', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (733, 'Dane Coad', '5 Miller Lane', '385-(373)651-7756', 'dcoadkc@npr.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (734, 'Phylys Franzetti', '6123 Roth Avenue', '63-(227)183-5876', 'pfranzettikd@nyu.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (735, 'Roberta Joselevitz', '9 Rigney Way', '33-(324)363-1641', 'rjoselevitzke@google.co.uk', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (736, 'Obediah Mulliner', '7387 Susan Point', '66-(484)895-0126', 'omullinerkf@amazon.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (737, 'Rodrigo Minogue', '255 Amoth Point', '7-(635)890-2444', 'rminoguekg@seattletimes.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (738, 'Pierce Olrenshaw', '44022 Hansons Lane', '86-(964)459-0304', 'polrenshawkh@hugedomains.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (739, 'Dacy Loughton', '419 Bunker Hill Avenue', '86-(650)499-5217', 'dloughtonki@si.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (740, 'Roosevelt Maryska', '27 Tennyson Point', '86-(579)737-0853', 'rmaryskakj@nih.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (741, 'Erina Keogh', '3715 Lunder Drive', '62-(177)735-1222', 'ekeoghkk@t.co', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (742, 'Stanislaus Drogan', '27 Stephen Junction', '86-(414)384-0012', 'sdrogankl@prlog.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (743, 'Cyndy Ivanitsa', '7 Drewry Street', '86-(762)904-3992', 'civanitsakm@wiley.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (744, 'Lynnette Horry', '882 Del Sol Place', '63-(275)303-0300', 'lhorrykn@auda.org.au', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (745, 'Marleen Parrington', '54 Tony Park', '63-(501)906-4332', 'mparringtonko@unc.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (746, 'Vincent Ranaghan', '119 Oakridge Way', '55-(641)824-6140', 'vranaghankp@sina.com.cn', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (747, 'Consolata Bein', '08 Morrow Center', '62-(678)396-5451', 'cbeinkq@sciencedaily.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (748, 'Elana Anstey', '6289 Pawling Trail', '44-(624)749-0623', 'eansteykr@reddit.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (749, 'Lacie Lambrick', '928 Goodland Place', '254-(337)576-3604', 'llambrickks@desdev.cn', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (750, 'Lizabeth Leaf', '3458 Golf Avenue', '64-(382)402-9387', 'lleafkt@oaic.gov.au', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (751, 'Fairleigh Minigo', '56 Autumn Leaf Court', '51-(875)689-6424', 'fminigoku@vinaora.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (752, 'Veronike Brettell', '2 Grasskamp Park', '33-(453)578-1405', 'vbrettellkv@telegraph.co.uk', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (753, 'Prue Graysmark', '826 Randy Place', '63-(231)299-1533', 'pgraysmarkkw@bbc.co.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (754, 'Drud Farnin', '09603 American Ash Court', '63-(459)221-0551', 'dfarninkx@bloomberg.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (755, 'Blayne Jankovsky', '088 Veith Circle', '62-(152)182-7754', 'bjankovskyky@freewebs.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (756, 'Thorny Stallon', '78839 Montana Lane', '86-(339)710-2483', 'tstallonkz@amazon.co.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (757, 'Roddy Alliker', '7 Pleasure Alley', '66-(609)179-7702', 'rallikerl0@irs.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (758, 'Merrili McCusker', '96 Heffernan Lane', '964-(461)519-2218', 'mmccuskerl1@earthlink.net', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (759, 'Portie Ivanyutin', '065 Blue Bill Park Drive', '62-(947)177-5333', 'pivanyutinl2@ustream.tv', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (760, 'Lucien Meynell', '07 Dawn Circle', '381-(898)154-1834', 'lmeynelll3@constantcontact.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (761, 'Jeane Autie', '83 Basil Plaza', '86-(200)673-8162', 'jautiel4@time.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (762, 'Ayn Lowder', '65817 Shasta Trail', '7-(768)260-6066', 'alowderl5@live.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (763, 'Berni Courtney', '7 Armistice Road', '55-(612)343-1086', 'bcourtneyl6@wsj.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (764, 'Andeee Feldmann', '3 Lake View Alley', '55-(156)521-7024', 'afeldmannl7@wordpress.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (765, 'Towney Gowry', '5397 Maywood Way', '86-(218)902-0780', 'tgowryl8@unesco.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (766, 'Patton Littlejohns', '0126 Surrey Point', '7-(254)785-7103', 'plittlejohnsl9@pcworld.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (767, 'Tess Cristoforetti', '40785 Shasta Center', '86-(795)177-1850', 'tcristoforettila@unicef.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (768, 'Adriana Bollon', '92 Arrowood Street', '66-(360)323-1616', 'abollonlb@wix.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (769, 'Man Wrightson', '0 Thompson Street', '81-(199)266-8051', 'mwrightsonlc@cyberchimps.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (770, 'Burke Gillion', '17030 Crownhardt Parkway', '970-(976)688-3038', 'bgillionld@shareasale.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (771, 'Wait Tunbridge', '04 Alpine Alley', '7-(184)329-5606', 'wtunbridgele@newyorker.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (772, 'Christi Wykes', '2 Schurz Park', '63-(817)415-8489', 'cwykeslf@china.com.cn', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (773, 'Prudy Smithen', '0164 Lighthouse Bay Center', '62-(413)111-7684', 'psmithenlg@mit.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (774, 'Chandal Szymanowski', '4 Straubel Pass', '46-(356)966-0306', 'cszymanowskilh@oaic.gov.au', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (775, 'Coraline Mooring', '5 Twin Pines Road', '977-(702)672-8679', 'cmooringli@nature.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (776, 'Jeramie Routham', '2 Bluejay Way', '880-(867)368-0717', 'jrouthamlj@usgs.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (777, 'Carlin O'' Clovan', '7389 Ruskin Alley', '62-(316)560-4574', 'colk@aboutads.info', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (778, 'Kingston Rodgers', '208 Loeprich Drive', '48-(973)460-8648', 'krodgersll@google.es', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (779, 'Teodoro Catonne', '4 Mockingbird Circle', '967-(460)440-2641', 'tcatonnelm@arizona.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (780, 'Emera Ralls', '5 Aberg Circle', '51-(666)926-8621', 'erallsln@mit.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (781, 'Tony Dronsfield', '7 Butternut Street', '7-(492)672-3990', 'tdronsfieldlo@redcross.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (782, 'Marjorie McErlaine', '52753 Waxwing Alley', '51-(482)505-1791', 'mmcerlainelp@merriam-webster.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (783, 'Ludvig Ferriman', '0 Lawn Center', '506-(182)801-5215', 'lferrimanlq@merriam-webster.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (784, 'Isiahi Brunnstein', '0724 Del Mar Road', '62-(954)981-8147', 'ibrunnsteinlr@mtv.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (785, 'Jessey Leethem', '178 Spenser Place', '351-(326)570-8181', 'jleethemls@europa.eu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (786, 'Natalina Mellhuish', '66302 Forest Dale Circle', '385-(160)208-8426', 'nmellhuishlt@posterous.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (787, 'Trixi Hankin', '7325 Porter Junction', '86-(772)663-6721', 'thankinlu@google.it', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (788, 'Duncan Giddens', '0335 Loomis Center', '380-(911)425-7074', 'dgiddenslv@surveymonkey.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (789, 'Geoffry Warlowe', '12 Schiller Junction', '51-(619)448-8603', 'gwarlowelw@e-recht24.de', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (790, 'Sam Fylan', '81 Farmco Park', '351-(501)497-8801', 'sfylanlx@linkedin.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (791, 'Ede Cootes', '403 Mariners Cove Avenue', '63-(560)971-2394', 'ecootesly@twitpic.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (792, 'Tremaine Dowthwaite', '679 Arizona Road', '269-(552)289-9147', 'tdowthwaitelz@telegraph.co.uk', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (793, 'Dido Bowgen', '9 Packers Park', '33-(347)174-6044', 'dbowgenm0@dyndns.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (794, 'Sinclair Brame', '867 Melrose Pass', '62-(205)146-1673', 'sbramem1@dell.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (795, 'Estele Bover', '5783 Delladonna Trail', '234-(167)671-0352', 'eboverm2@ocn.ne.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (796, 'Vittorio McGarel', '2280 Butterfield Pass', '7-(164)741-0134', 'vmcgarelm3@wikipedia.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (797, 'Gerek Milverton', '71448 Milwaukee Plaza', '33-(672)998-1787', 'gmilvertonm4@army.mil', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (798, 'Dode Tuminelli', '79 8th Center', '86-(982)588-7861', 'dtuminellim5@nba.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (799, 'Petra Quirk', '8085 Susan Avenue', '86-(114)395-6910', 'pquirkm6@mayoclinic.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (800, 'Silvanus Haggerston', '525 Oxford Drive', '62-(221)556-9290', 'shaggerstonm7@w3.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (801, 'Shanon Mosson', '26046 Erie Crossing', '7-(472)313-9540', 'smossonm8@myspace.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (802, 'Charisse Hedges', '6 Browning Court', '383-(550)704-9891', 'chedgesm9@ebay.co.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (803, 'Gleda Niesing', '3 Fair Oaks Circle', '357-(990)853-6702', 'gniesingma@nba.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (804, 'Jordan Dady', '02641 Cascade Trail', '52-(953)684-6055', 'jdadymb@exblog.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (805, 'Odessa Stoppe', '04 Darwin Place', '62-(450)443-5270', 'ostoppemc@ebay.co.uk', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (806, 'Selestina Wayvill', '82432 Autumn Leaf Terrace', '55-(895)758-5020', 'swayvillmd@ocn.ne.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (807, 'Bernice Midgley', '28 Amoth Circle', '62-(619)888-8258', 'bmidgleyme@cafepress.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (808, 'Carla Probart', '087 Rutledge Avenue', '244-(573)124-7617', 'cprobartmf@theatlantic.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (809, 'Booth Gransden', '0303 Lawn Crossing', '86-(313)383-8082', 'bgransdenmg@bloglovin.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (810, 'Walton Grishukov', '935 Graceland Terrace', '31-(407)579-0462', 'wgrishukovmh@europa.eu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (811, 'Ceciley Marrill', '75 Melrose Point', '98-(324)920-6208', 'cmarrillmi@ucoz.ru', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (812, 'Adorne Glyssanne', '1 Hoffman Road', '505-(733)569-2559', 'aglyssannemj@webnode.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (813, 'Ernestus Spinige', '7088 Mitchell Court', '7-(434)331-3999', 'espinigemk@google.de', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (814, 'Nikolia Skelhorn', '98 Linden Lane', '880-(987)938-4195', 'nskelhornml@google.com.br', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (815, 'Lissi Farncombe', '1009 Elka Place', '230-(366)551-3750', 'lfarncombemm@histats.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (816, 'Janeen Edelmann', '704 Hoffman Plaza', '420-(707)505-2970', 'jedelmannmn@hao123.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (817, 'Daryn Campsall', '55 Cottonwood Trail', '62-(518)256-7711', 'dcampsallmo@whitehouse.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (818, 'Jena Dunthorne', '00 Fairfield Drive', '1-(253)928-8950', 'jdunthornemp@topsy.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (819, 'Marita Baldock', '1771 Buell Drive', '63-(550)875-8239', 'mbaldockmq@liveinternet.ru', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (820, 'Margalo Barron', '41137 Waxwing Lane', '62-(964)775-0346', 'mbarronmr@icio.us', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (821, 'Christiana Crippell', '8 Sachtjen Park', '235-(612)637-4202', 'ccrippellms@kickstarter.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (822, 'Zelig Bonnell', '4 Bartillon Drive', '675-(513)836-2298', 'zbonnellmt@google.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (823, 'Colleen Maddicks', '4 Glacier Hill Point', '81-(474)541-5485', 'cmaddicksmu@fema.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (824, 'Fredek Labarre', '01 Declaration Center', '420-(904)515-6777', 'flabarremv@so-net.ne.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (825, 'Bear Westoff', '045 Darwin Trail', '351-(677)926-6253', 'bwestoffmw@macromedia.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (826, 'Carree Jecks', '2 Golf Course Crossing', '62-(838)441-4338', 'cjecksmx@businessweek.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (827, 'Kassey Alans', '6730 Roth Court', '63-(997)357-1356', 'kalansmy@narod.ru', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (828, 'Nada Jowle', '5 Red Cloud Circle', '81-(909)466-8958', 'njowlemz@twitter.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (829, 'Kilian Tretter', '4957 Thompson Court', '56-(968)361-1248', 'ktrettern0@yolasite.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (830, 'Adelina De Paoli', '6409 Dovetail Plaza', '221-(882)819-5246', 'aden1@irs.gov', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (831, 'Harbert Gail', '768 Meadow Valley Plaza', '358-(733)753-0773', 'hgailn2@nba.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (832, 'Deonne Lyndon', '158 Sage Avenue', '62-(808)183-0900', 'dlyndonn3@whitehouse.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (833, 'Gwenneth Frenchum', '2 Fuller Parkway', '380-(212)669-7724', 'gfrenchumn4@furl.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (834, 'Clair Rummings', '0989 Huxley Place', '880-(396)333-1250', 'crummingsn5@dell.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (835, 'Dorry Fyers', '549 Sunbrook Crossing', '7-(477)479-4114', 'dfyersn6@etsy.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (836, 'Jerrome Galliver', '494 Vidon Hill', '86-(821)460-5979', 'jgallivern7@globo.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (837, 'Dehlia Clampin', '23 Truax Alley', '7-(688)233-3022', 'dclampinn8@dagondesign.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (838, 'Edna Caris', '2 Stephen Way', '30-(153)103-4705', 'ecarisn9@latimes.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (839, 'Rupert Castanie', '14 Dayton Court', '62-(627)762-1678', 'rcastaniena@marketwatch.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (840, 'Patrick Stempe', '896 Kingsford Circle', '62-(560)869-7564', 'pstempenb@trellian.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (841, 'Hilton Witham', '8519 Burrows Place', '81-(880)422-5822', 'hwithamnc@soundcloud.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (842, 'Richardo Mills', '0 Homewood Crossing', '62-(387)708-1177', 'rmillsnd@yellowbook.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (843, 'Chuck Hulls', '3353 Milwaukee Trail', '86-(139)836-7481', 'chullsne@hatena.ne.jp', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (844, 'Louie Everingham', '44 Walton Avenue', '7-(927)126-4970', 'leveringhamnf@odnoklassniki.ru', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (845, 'Terencio Waind', '3131 Thompson Crossing', '30-(199)853-7393', 'twaindng@vistaprint.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (846, 'Odell Lagde', '9 Sheridan Drive', '62-(889)400-3972', 'olagdenh@rakuten.co.jp', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (847, 'Elsy Godier', '63 Banding Park', '1-(205)467-5170', 'egodierni@sfgate.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (848, 'Dotti Checchetelli', '45418 Helena Way', '62-(215)480-1503', 'dchecchetellinj@digg.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (849, 'Laurie Seilmann', '792 Steensland Road', '86-(736)127-7046', 'lseilmannnk@360.cn', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (850, 'Christian Deem', '1492 3rd Avenue', '86-(171)702-3093', 'cdeemnl@csmonitor.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (851, 'Phyllida Stonehewer', '5 Prentice Way', '82-(766)980-8641', 'pstonehewernm@telegraph.co.uk', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (852, 'Trudy Sharper', '5051 Longview Plaza', '55-(744)448-7007', 'tsharpernn@spotify.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (853, 'Bliss Capelen', '27697 Morrow Terrace', '55-(816)598-6953', 'bcapelenno@wikia.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (854, 'Heinrik Sabati', '42 Pond Place', '964-(545)537-2850', 'hsabatinp@icq.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (855, 'Ignazio Oxbie', '53962 Kings Trail', '48-(575)282-7091', 'ioxbienq@state.tx.us', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (856, 'Julieta Whistan', '75697 7th Center', '55-(381)692-2948', 'jwhistannr@princeton.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (857, 'Myranda Robertson', '38 Ilene Street', '33-(973)347-4843', 'mrobertsonns@jimdo.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (858, 'Irving Arrigucci', '519 Goodland Alley', '7-(266)744-7196', 'iarriguccint@webmd.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (859, 'Belicia Eden', '42 Coolidge Terrace', '1-(434)275-2413', 'bedennu@purevolume.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (860, 'Geoffrey Longega', '3 Fulton Way', '62-(844)187-8797', 'glongeganv@nationalgeographic.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (861, 'Maje Greenin', '225 Eggendart Avenue', '380-(633)711-5908', 'mgreeninnw@newyorker.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (862, 'Camile Minards', '81260 Coleman Lane', '63-(486)996-5222', 'cminardsnx@purevolume.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (863, 'Joe O''Hagirtie', '53 Anniversary Circle', '33-(270)575-5085', 'johagirtieny@paginegialle.it', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (864, 'Min Salasar', '9917 Nobel Center', '62-(419)505-8360', 'msalasarnz@ning.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (865, 'Robinson Darling', '209 Oriole Circle', '86-(926)519-3108', 'rdarlingo0@lulu.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (866, 'Brena Dahill', '625 Meadow Vale Junction', '380-(978)297-9635', 'bdahillo1@netlog.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (867, 'Solly Mowsdill', '70090 Loeprich Lane', '351-(567)867-7495', 'smowsdillo2@forbes.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (868, 'Alyosha Wise', '54421 Homewood Way', '84-(940)617-2430', 'awiseo3@narod.ru', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (869, 'Banky Maving', '7669 Westerfield Crossing', '380-(532)809-9818', 'bmavingo4@jugem.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (870, 'Culley Orgee', '9404 Di Loreto Way', '81-(357)943-6445', 'corgeeo5@tuttocitta.it', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (871, 'Aguistin Prate', '71 Beilfuss Court', '54-(851)958-2625', 'aprateo6@npr.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (872, 'Salomi Hembery', '1 Bluejay Park', '53-(802)442-6153', 'shemberyo7@ca.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (873, 'Bari Govey', '06618 Gerald Alley', '992-(623)746-9422', 'bgoveyo8@issuu.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (874, 'Shanda Petroulis', '581 Dapin Parkway', '685-(830)872-3347', 'spetrouliso9@zimbio.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (875, 'Nertie Geraldez', '5159 Grayhawk Junction', '252-(338)871-7803', 'ngeraldezoa@163.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (876, 'Eben Stoate', '5849 Mallard Center', '63-(383)407-2691', 'estoateob@patch.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (877, 'Solomon Bonham', '69 Golf View Hill', '62-(484)120-6362', 'sbonhamoc@addtoany.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (878, 'Tatiana Berget', '14 Sage Point', '81-(509)887-1203', 'tbergetod@clickbank.net', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (879, 'Cindra Lang', '52 Atwood Alley', '62-(621)346-1132', 'clangoe@ihg.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (880, 'Marinna Cadle', '4303 Lawn Lane', '62-(546)655-2861', 'mcadleof@forbes.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (881, 'Corina Pfleger', '7146 Rowland Street', '62-(218)987-6713', 'cpflegerog@cpanel.net', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (882, 'Lizette Pyrah', '672 Fuller Hill', '505-(526)536-3411', 'lpyrahoh@163.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (883, 'Clarke Hutable', '364 Grasskamp Trail', '62-(761)548-6702', 'chutableoi@icq.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (884, 'Chere Cotterill', '7 Blue Bill Park Way', '234-(427)655-5950', 'ccotterilloj@behance.net', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (885, 'Glyn Lagne', '1495 Reindahl Parkway', '33-(143)275-7194', 'glagneok@psu.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (886, 'Chevalier Tate', '0 Lunder Drive', '7-(809)949-0045', 'ctateol@nationalgeographic.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (887, 'Maddalena Sone', '8 Kingsford Crossing', '86-(598)123-5417', 'msoneom@sourceforge.net', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (888, 'Logan Fancet', '9 Bartelt Point', '62-(654)400-2212', 'lfanceton@de.vu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (889, 'Minerva Hibbart', '9 Everett Hill', '54-(583)399-3882', 'mhibbartoo@livejournal.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (890, 'Fidole Bison', '74 Stone Corner Junction', '86-(883)388-3634', 'fbisonop@geocities.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (891, 'Austine Marzelli', '994 Hooker Road', '51-(336)877-0856', 'amarzellioq@columbia.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (892, 'Boony Little', '2 Veith Lane', '7-(730)190-8010', 'blittleor@examiner.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (893, 'Pattie McQuie', '68365 Trailsway Plaza', '591-(540)109-8835', 'pmcquieos@stumbleupon.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (894, 'Malorie Antrag', '2 Washington Pass', '55-(132)730-0513', 'mantragot@skype.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (895, 'Roderic Searston', '16 Brown Place', '237-(765)164-2890', 'rsearstonou@edublogs.org', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (896, 'Druci Remmer', '74 Donald Plaza', '51-(168)232-0942', 'dremmerov@dailymail.co.uk', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (897, 'Mikaela Ingman', '73446 Shoshone Terrace', '86-(335)430-2334', 'mingmanow@ameblo.jp', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (898, 'Eziechiele Justice', '591 Clyde Gallagher Junction', '234-(565)715-8664', 'ejusticeox@i2i.jp', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (899, 'Nollie Peddar', '5525 Killdeer Crossing', '34-(452)920-2003', 'npeddaroy@apache.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (900, 'Raddie Thurling', '6745 Arapahoe Pass', '84-(342)676-8510', 'rthurlingoz@discovery.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (901, 'Burton Biskupski', '14083 Logan Plaza', '86-(660)170-2886', 'bbiskupskip0@theatlantic.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (902, 'Lindy MacAllaster', '725 Kipling Junction', '353-(793)932-9564', 'lmacallasterp1@google.co.uk', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (903, 'Torrie Cleveley', '491 Golf Course Place', '1-(502)595-8074', 'tcleveleyp2@dot.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (904, 'Saleem Juden', '51 Vermont Way', '62-(374)463-2272', 'sjudenp3@ehow.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (905, 'Michelina Ortes', '626 Cordelia Avenue', '86-(464)500-3196', 'mortesp4@admin.ch', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (906, 'Raff Dallan', '09078 Washington Drive', '57-(508)104-2448', 'rdallanp5@is.gd', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (907, 'Archy McAughtry', '7028 Coolidge Avenue', '81-(347)759-3660', 'amcaughtryp6@walmart.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (908, 'Bertha MacPake', '75 Walton Plaza', '1-(423)596-0603', 'bmacpakep7@webeden.co.uk', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (909, 'Ronna Levens', '8161 Fulton Road', '55-(680)488-9152', 'rlevensp8@symantec.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (910, 'Darelle Lobe', '968 Aberg Point', '33-(651)642-0437', 'dlobep9@xrea.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (911, 'Hendrika Jost', '5163 2nd Way', '62-(181)776-8690', 'hjostpa@imgur.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (912, 'Chery Groocock', '150 Mesta Road', '33-(299)283-3401', 'cgroocockpb@ihg.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (913, 'Smith MacKibbon', '981 Merrick Circle', '1-(703)899-0926', 'smackibbonpc@state.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (914, 'Boyce Langshaw', '7 Division Court', '1-(317)426-0917', 'blangshawpd@walmart.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (915, 'Renard Joron', '2 Hallows Junction', '27-(795)721-0376', 'rjoronpe@themeforest.net', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (916, 'Marlyn Rikel', '9303 Parkside Point', '63-(182)926-4607', 'mrikelpf@bigcartel.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (917, 'Bidget Pes', '7175 Talisman Avenue', '55-(653)599-9107', 'bpespg@ocn.ne.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (918, 'Wynny Sleit', '0356 Lakeland Alley', '359-(394)480-6192', 'wsleitph@newsvine.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (919, 'Florry Tomaskunas', '059 Basil Point', '216-(687)191-9304', 'ftomaskunaspi@typepad.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (920, 'Ricard Alliot', '16204 Pleasure Drive', '351-(215)630-0883', 'ralliotpj@statcounter.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (921, 'Krissie Sandiland', '48093 John Wall Pass', '976-(333)123-5740', 'ksandilandpk@w3.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (922, 'Birch Fairpool', '15691 Northland Junction', '591-(762)861-3684', 'bfairpoolpl@geocities.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (923, 'Nev Trownson', '74 Green Ridge Hill', '45-(346)612-2663', 'ntrownsonpm@microsoft.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (924, 'Nolly Worstall', '292 Cottonwood Court', '380-(518)845-1725', 'nworstallpn@who.int', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (925, 'Corabelle Mosen', '56 Burning Wood Pass', '86-(815)130-6170', 'cmosenpo@photobucket.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (926, 'Adlai MacAlroy', '0361 Meadow Ridge Parkway', '63-(580)707-5295', 'amacalroypp@canalblog.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (927, 'Darill Firpo', '43570 Longview Avenue', '57-(639)991-7091', 'dfirpopq@nba.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (928, 'Tanya Moffet', '7 Oak Valley Plaza', '351-(689)757-1846', 'tmoffetpr@ow.ly', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (929, 'Natale Spacey', '163 Holy Cross Hill', '351-(543)762-9914', 'nspaceyps@altervista.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (930, 'Hinze Livzey', '3 Fair Oaks Trail', '86-(665)171-0807', 'hlivzeypt@aboutads.info', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (931, 'Jana Juggings', '36 Fairview Center', '63-(591)619-3537', 'jjuggingspu@discuz.net', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (932, 'Prent Prise', '6 Eagan Park', '86-(534)623-6353', 'pprisepv@vistaprint.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (933, 'Agosto Whistance', '53475 Vermont Trail', '66-(503)634-2543', 'awhistancepw@nyu.edu', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (934, 'Kile Curro', '6 Northwestern Center', '48-(545)620-7892', 'kcurropx@blogtalkradio.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (935, 'Putnam Coppeard', '8 Morning Street', '380-(727)179-7755', 'pcoppeardpy@loc.gov', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (936, 'Frank Tinker', '94 Debra Avenue', '63-(607)630-1064', 'ftinkerpz@arizona.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (937, 'Major Lobb', '6 Badeau Street', '351-(874)373-2812', 'mlobbq0@ca.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (938, 'Padriac McGhie', '095 Sutteridge Lane', '86-(750)210-2744', 'pmcghieq1@xinhuanet.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (939, 'Fredek Patesel', '11 Macpherson Parkway', '261-(706)392-8579', 'fpateselq2@cdbaby.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (940, 'Micaela Walkey', '50 Eastwood Junction', '86-(117)194-4048', 'mwalkeyq3@time.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (941, 'Gilly Alltimes', '6 Loomis Avenue', '86-(354)579-6006', 'galltimesq4@google.co.uk', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (942, 'Hester Tortis', '53530 Anzinger Park', '33-(109)516-1482', 'htortisq5@networksolutions.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (943, 'Brinna Corsan', '1 Lillian Street', '355-(427)691-1560', 'bcorsanq6@apple.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (944, 'Merell Harsnep', '1 Delladonna Place', '52-(690)679-2998', 'mharsnepq7@instagram.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (945, 'West Ghiroldi', '6168 Kedzie Road', '20-(439)703-8986', 'wghiroldiq8@time.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (946, 'Vere Zink', '0592 Thompson Lane', '81-(872)558-7419', 'vzinkq9@digg.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (947, 'Robinette Gladwell', '2 Crownhardt Crossing', '64-(661)921-1635', 'rgladwellqa@mapy.cz', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (948, 'Fleur Fleeman', '867 Bobwhite Pass', '62-(716)207-2290', 'ffleemanqb@yellowpages.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (949, 'Brennen Omar', '49 Stone Corner Street', '46-(896)179-6189', 'bomarqc@prweb.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (950, 'Allene Sudy', '79 Weeping Birch Parkway', '46-(826)141-3632', 'asudyqd@mayoclinic.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (951, 'Eberto Revelle', '593 Brickson Park Center', '46-(405)433-7628', 'erevelleqe@globo.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (952, 'Frayda Le Friec', '404 Sunbrook Place', '252-(456)549-0962', 'fleqf@harvard.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (953, 'Fairlie Keyes', '56 Sunfield Lane', '39-(822)167-1832', 'fkeyesqg@zdnet.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (954, 'Daile Cordero', '20346 Logan Plaza', '62-(822)878-8004', 'dcorderoqh@mediafire.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (955, 'Lilian De La Haye', '63 Ridgeway Junction', '63-(398)314-1611', 'ldeqi@businessweek.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (956, 'Grover Manz', '401 Lakewood Gardens Drive', '86-(384)468-6024', 'gmanzqj@jalbum.net', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (957, 'Claudie Redding', '81 Del Sol Circle', '62-(326)182-4762', 'creddingqk@nasa.gov', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (958, 'Allis Joskovitch', '6 Del Sol Drive', '355-(122)928-5015', 'ajoskovitchql@omniture.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (959, 'Kenton Mahaddy', '22 Welch Pass', '63-(382)992-0504', 'kmahaddyqm@ca.gov', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (960, 'Gretal Piniur', '163 Northwestern Drive', '54-(328)594-9183', 'gpiniurqn@pagesperso-orange.fr', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (961, 'Aurie Burgiss', '58198 Arrowood Place', '62-(617)976-6243', 'aburgissqo@blogs.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (962, 'Shaylynn Bird', '5741 Thackeray Hill', '93-(444)353-2164', 'sbirdqp@facebook.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (963, 'Lowell Meffan', '4701 Mcguire Alley', '54-(795)457-6155', 'lmeffanqq@globo.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (964, 'Sherlock Gilder', '38991 Hazelcrest Lane', '7-(859)238-1381', 'sgilderqr@phpbb.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (965, 'Elsbeth Scarr', '15013 High Crossing Street', '55-(633)392-0464', 'escarrqs@smugmug.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (966, 'Berta Letham', '4 Linden Park', '33-(414)577-9848', 'blethamqt@xing.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (967, 'Gabriele Sowrey', '346 Bartelt Park', '34-(175)823-5472', 'gsowreyqu@parallels.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (968, 'Gregorio Scanlan', '4 Susan Park', '353-(667)392-2890', 'gscanlanqv@surveymonkey.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (969, 'Jaquelin Broschek', '2488 Monument Hill', '269-(252)148-3431', 'jbroschekqw@dmoz.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (970, 'Adda Corsham', '99974 Nobel Hill', '55-(655)206-3999', 'acorshamqx@buzzfeed.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (971, 'Kaylee Dunham', '5671 Rockefeller Lane', '850-(346)862-3002', 'kdunhamqy@ycombinator.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (972, 'Nahum Mastrantone', '26059 Saint Paul Way', '269-(903)958-8508', 'nmastrantoneqz@usgs.gov', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (973, 'Harcourt O''Corhane', '85 Harper Drive', '263-(714)880-2973', 'hocorhaner0@cnn.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (974, 'Sven Cadwallader', '010 Heffernan Lane', '48-(819)296-7208', 'scadwalladerr1@geocities.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (975, 'Vernor Espinoza', '62633 Eggendart Court', '56-(385)957-8890', 'vespinozar2@e-recht24.de', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (976, 'Arni McFadin', '79 Forest Junction', '47-(905)476-8230', 'amcfadinr3@epa.gov', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (977, 'Anabella Amey', '272 Morrow Crossing', '62-(803)725-6061', 'aameyr4@marketwatch.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (978, 'Franny Jelliman', '9 Badeau Pass', '351-(337)624-6360', 'fjellimanr5@biglobe.ne.jp', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (979, 'Hattie Brettelle', '47212 Sachtjen Way', '381-(820)405-2054', 'hbretteller6@techcrunch.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (980, 'Gian Jex', '9751 Shoshone Center', '66-(417)747-4852', 'gjexr7@prlog.org', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (981, 'Rab Cromly', '76668 Carioca Place', '53-(805)801-3629', 'rcromlyr8@123-reg.co.uk', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (982, 'Gratia Salsbury', '25257 Fremont Hill', '55-(657)354-6091', 'gsalsburyr9@facebook.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (983, 'Albert Metzke', '1065 Birchwood Circle', '86-(186)472-1830', 'ametzkera@mail.ru', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (984, 'Damiano O''Hoolahan', '5277 Elgar Circle', '86-(474)358-2803', 'dohoolahanrb@uol.com.br', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (985, 'Domeniga Sarginson', '47 Golden Leaf Hill', '389-(407)818-3674', 'dsarginsonrc@zimbio.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (986, 'Horst Newton', '0 Independence Alley', '86-(972)119-2252', 'hnewtonrd@washingtonpost.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (987, 'Petey Reschke', '1 Victoria Plaza', '7-(293)369-3068', 'preschkere@amazonaws.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (988, 'Yvonne Papps', '81672 8th Alley', '86-(983)516-3088', 'ypappsrf@theglobeandmail.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (989, 'Gaylor Puvia', '72434 Arapahoe Lane', '970-(739)496-7075', 'gpuviarg@nyu.edu', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (990, 'Benito Jeaffreson', '6 Jay Trail', '62-(818)430-6351', 'bjeaffresonrh@mtv.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (991, 'Duffie MacElroy', '41856 Shasta Terrace', '86-(604)927-0823', 'dmacelroyri@alexa.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (992, 'Corny Ganford', '03147 Maple Road', '381-(878)682-8450', 'cganfordrj@mashable.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (993, 'Casar Gunningham', '71255 Hooker Junction', '86-(775)361-3947', 'cgunninghamrk@merriam-webster.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (994, 'Roberta New', '3 Fisk Hill', '351-(716)551-6873', 'rnewrl@stumbleupon.com', 'S', NULL, NULL, NULL, NULL, 2, NULL);
INSERT INTO cliente VALUES (995, 'Salli Goldsack', '858 Kings Lane', '509-(500)132-9638', 'sgoldsackrm@slashdot.org', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (996, 'Lynea Mitchelson', '92926 Michigan Park', '86-(427)671-9506', 'lmitchelsonrn@shinystat.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (997, 'Lilias Ryle', '402 Weeping Birch Trail', '48-(643)491-3466', 'lrylero@alexa.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (998, 'Luella Perry', '4 Monterey Plaza', '54-(875)967-2532', 'lperryrp@booking.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (999, 'Tiphanie Ashard', '4286 Delladonna Lane', '1-(887)502-2335', 'tashardrq@marketwatch.com', 'S', NULL, NULL, NULL, NULL, 3, NULL);
INSERT INTO cliente VALUES (1000, 'Chickie Moffet', '38807 Roth Trail', '60-(977)121-5782', 'cmoffetrr@photobucket.com', 'S', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (1036, 'Herlin R. espinosa', 'Recta Cali - Palmira', '4450000', 'hespinosa@cgiar.org', 'N', NULL, NULL, NULL, NULL, 1, NULL);
INSERT INTO cliente VALUES (2, 'Jerrie Cannell dfdfd', '5 Ridgeview Junction', '46-(124)837-1565', 'jcannell1@stanford.edu', 'S', NULL, NULL, NULL, NULL, 3, NULL);


--
-- TOC entry 2289 (class 0 OID 35142)
-- Dependencies: 189
-- Data for Name: cuenta; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO cuenta VALUES ('4640-0341-9387-5781', 2032719.000000, 'JIxErs', 'S', NULL, NULL, NULL, NULL, 860);
INSERT INTO cuenta VALUES ('1630-2511-2937-7299', 9440475.000000, 'tRVxmv', 'S', NULL, NULL, NULL, NULL, 346);
INSERT INTO cuenta VALUES ('6592-7866-3024-5314', 511124.000000, 'q3ILjU', 'S', NULL, NULL, NULL, NULL, 67);
INSERT INTO cuenta VALUES ('1475-4858-1691-5789', 1046803.000000, 'ApM6psxOaje', 'S', NULL, NULL, NULL, NULL, 627);
INSERT INTO cuenta VALUES ('9065-8351-4489-8687', 1944362.000000, 'EKShGhYyuAL', 'S', NULL, NULL, NULL, NULL, 550);
INSERT INTO cuenta VALUES ('2928-4331-8647-0560', 6263784.000000, 'Dj2FI8Lp', 'S', NULL, NULL, NULL, NULL, 76);
INSERT INTO cuenta VALUES ('7173-6253-2005-9312', 8265355.000000, 'OqvuJLeoer2', 'S', NULL, NULL, NULL, NULL, 273);
INSERT INTO cuenta VALUES ('6939-8463-2899-6921', 6430247.000000, 'ce2vOKL', 'S', NULL, NULL, NULL, NULL, 351);
INSERT INTO cuenta VALUES ('1215-0877-5497-4162', 1539526.000000, 'gfY9Adtmd', 'S', NULL, NULL, NULL, NULL, 580);
INSERT INTO cuenta VALUES ('2632-3183-7851-1820', 7986255.000000, '2zburWRK', 'S', NULL, NULL, NULL, NULL, 357);
INSERT INTO cuenta VALUES ('9935-9879-2260-2925', 7636524.000000, 'bYEFVno', 'S', NULL, NULL, NULL, NULL, 867);
INSERT INTO cuenta VALUES ('9964-7808-5543-3283', 5507092.000000, 'fuqzrNSsKSgV', 'S', NULL, NULL, NULL, NULL, 613);
INSERT INTO cuenta VALUES ('1029-9774-2970-1730', 2077716.000000, 'm6OwfiYfGm7a', 'S', NULL, NULL, NULL, NULL, 502);
INSERT INTO cuenta VALUES ('4542-3132-7580-5698', 5238493.000000, 'S8YqUQqLrsS', 'S', NULL, NULL, NULL, NULL, 986);
INSERT INTO cuenta VALUES ('5476-9906-2825-9952', 6950425.000000, 'JGyTirQ2VaJT', 'S', NULL, NULL, NULL, NULL, 74);
INSERT INTO cuenta VALUES ('3730-3787-8629-3917', 7313221.000000, 'MxukPL2XdQ6V', 'S', NULL, NULL, NULL, NULL, 109);
INSERT INTO cuenta VALUES ('1178-7900-5881-6552', 3290412.000000, '7eM629', 'S', NULL, NULL, NULL, NULL, 304);
INSERT INTO cuenta VALUES ('5318-9901-9863-4382', 5637592.000000, '3niRp4GxCi', 'S', NULL, NULL, NULL, NULL, 371);
INSERT INTO cuenta VALUES ('0350-1117-8856-7980', 4854617.000000, 'v5CsTA', 'S', NULL, NULL, NULL, NULL, 584);
INSERT INTO cuenta VALUES ('6583-2282-3212-0467', 9234038.000000, '2uOhoxSfD', 'S', NULL, NULL, NULL, NULL, 740);
INSERT INTO cuenta VALUES ('1541-4277-0660-4459', 6977900.000000, 'h5K6dyJc', 'S', NULL, NULL, NULL, NULL, 621);
INSERT INTO cuenta VALUES ('9590-2625-2150-7258', 3968294.000000, 'qI96Uy', 'S', NULL, NULL, NULL, NULL, 964);
INSERT INTO cuenta VALUES ('0636-0754-0405-3314', 258294.000000, 'unPutqmXr', 'S', NULL, NULL, NULL, NULL, 578);
INSERT INTO cuenta VALUES ('2363-7005-2893-4182', 5508865.000000, 'xu4M65', 'S', NULL, NULL, NULL, NULL, 179);
INSERT INTO cuenta VALUES ('1683-9992-4718-7113', 5076722.000000, 'e3d2DOw2Z', 'S', NULL, NULL, NULL, NULL, 842);
INSERT INTO cuenta VALUES ('5095-6341-6973-5274', 5338535.000000, 'MfDfDwyewdL', 'S', NULL, NULL, NULL, NULL, 72);
INSERT INTO cuenta VALUES ('9181-1189-4069-8436', 442143.000000, 'UWUxPAY1', 'S', NULL, NULL, NULL, NULL, 607);
INSERT INTO cuenta VALUES ('1866-9428-1104-6886', 1854237.000000, 'bJ5IchKnN', 'S', NULL, NULL, NULL, NULL, 466);
INSERT INTO cuenta VALUES ('8278-7710-7311-4788', 2691928.000000, 'SUnyn9O', 'S', NULL, NULL, NULL, NULL, 325);
INSERT INTO cuenta VALUES ('4064-9491-1791-9866', 7519975.000000, 'F8osTL', 'S', NULL, NULL, NULL, NULL, 638);
INSERT INTO cuenta VALUES ('0117-2729-2666-4999', 557902.000000, '1MJQx4esrv', 'S', NULL, NULL, NULL, NULL, 720);
INSERT INTO cuenta VALUES ('9455-7519-9184-1316', 6962963.000000, 'FcvqrHmR0', 'S', NULL, NULL, NULL, NULL, 481);
INSERT INTO cuenta VALUES ('4489-2174-0669-7685', 8982788.000000, 'OF4vspg', 'S', NULL, NULL, NULL, NULL, 698);
INSERT INTO cuenta VALUES ('6760-5797-6026-8236', 7869445.000000, 'PtXra6CIJ', 'S', NULL, NULL, NULL, NULL, 683);
INSERT INTO cuenta VALUES ('0475-0347-5867-3706', 2312424.000000, 'BylwWEW50y0', 'S', NULL, NULL, NULL, NULL, 622);
INSERT INTO cuenta VALUES ('1164-3535-1779-9752', 7914658.000000, 'UEPpYC8bMD', 'S', NULL, NULL, NULL, NULL, 634);
INSERT INTO cuenta VALUES ('8918-2649-5470-5706', 318044.000000, 'xlY71Wz', 'S', NULL, NULL, NULL, NULL, 279);
INSERT INTO cuenta VALUES ('6499-7973-8172-6081', 4480641.000000, 'e5GUGpNJ0cM', 'S', NULL, NULL, NULL, NULL, 48);
INSERT INTO cuenta VALUES ('8466-6269-4466-4874', 9934813.000000, 'pbVi88kjs', 'S', NULL, NULL, NULL, NULL, 622);
INSERT INTO cuenta VALUES ('9999-8370-6668-7190', 1176090.000000, 'hH6Fbkmgam', 'S', NULL, NULL, NULL, NULL, 999);
INSERT INTO cuenta VALUES ('7116-7842-3370-2242', 7457735.000000, '7g9ae5', 'S', NULL, NULL, NULL, NULL, 708);
INSERT INTO cuenta VALUES ('7761-2171-6893-8685', 5027241.000000, 'XOhKKha', 'S', NULL, NULL, NULL, NULL, 551);
INSERT INTO cuenta VALUES ('7486-5639-1437-3118', 4982387.000000, 'AtlVF2aYgK', 'S', NULL, NULL, NULL, NULL, 288);
INSERT INTO cuenta VALUES ('3407-5270-2479-7393', 9417223.000000, 'TxRT2PXRzn99', 'S', NULL, NULL, NULL, NULL, 793);
INSERT INTO cuenta VALUES ('2079-4572-9595-5154', 9128749.000000, 'zWFiLP', 'S', NULL, NULL, NULL, NULL, 198);
INSERT INTO cuenta VALUES ('6758-7942-1548-0121', 3694831.000000, 'uHFdem5VobM', 'S', NULL, NULL, NULL, NULL, 58);
INSERT INTO cuenta VALUES ('9591-3296-4863-4542', 5029960.000000, '3Ao0bdop37ul', 'S', NULL, NULL, NULL, NULL, 685);
INSERT INTO cuenta VALUES ('1189-7024-1496-1936', 605748.000000, 'lbnGUEv', 'S', NULL, NULL, NULL, NULL, 473);
INSERT INTO cuenta VALUES ('2632-8850-8767-6806', 1302065.000000, '4JzjcyVv', 'S', NULL, NULL, NULL, NULL, 123);
INSERT INTO cuenta VALUES ('9505-0277-8346-3969', 5323827.000000, 'py6ALK', 'S', NULL, NULL, NULL, NULL, 138);
INSERT INTO cuenta VALUES ('2139-8397-7084-4093', 3618821.000000, 'TGXMya71', 'S', NULL, NULL, NULL, NULL, 324);
INSERT INTO cuenta VALUES ('8496-8115-5596-9722', 2130122.000000, '818AH4KH', 'S', NULL, NULL, NULL, NULL, 523);
INSERT INTO cuenta VALUES ('1078-8795-8240-6760', 4184365.000000, 'gXWaIEuvRO54', 'S', NULL, NULL, NULL, NULL, 545);
INSERT INTO cuenta VALUES ('6447-3132-2386-3059', 7263569.000000, 'K5ZkOl4R', 'S', NULL, NULL, NULL, NULL, 346);
INSERT INTO cuenta VALUES ('4868-7136-8392-3176', 8901837.000000, 'O7ISjty65CBK', 'S', NULL, NULL, NULL, NULL, 124);
INSERT INTO cuenta VALUES ('3803-6035-3793-4001', 2562787.000000, 't4Ort5UKql', 'S', NULL, NULL, NULL, NULL, 786);
INSERT INTO cuenta VALUES ('4491-5667-1554-9630', 9662152.000000, 'KRqRCtkJqN', 'S', NULL, NULL, NULL, NULL, 413);
INSERT INTO cuenta VALUES ('0268-5280-7709-0786', 1169175.000000, 'OCTSpgP', 'S', NULL, NULL, NULL, NULL, 249);
INSERT INTO cuenta VALUES ('8949-3946-3107-0179', 8318990.000000, 'dkRTG8HdP', 'S', NULL, NULL, NULL, NULL, 989);
INSERT INTO cuenta VALUES ('6121-8028-2625-4222', 5492679.000000, 'MMbS9vaeFIuA', 'S', NULL, NULL, NULL, NULL, 188);
INSERT INTO cuenta VALUES ('8745-0201-1661-2523', 5766611.000000, 'p6NkVN3y', 'S', NULL, NULL, NULL, NULL, 92);
INSERT INTO cuenta VALUES ('4935-1821-8202-2968', 7355366.000000, 'RmUoiT', 'S', NULL, NULL, NULL, NULL, 689);
INSERT INTO cuenta VALUES ('6746-5524-6238-5271', 5076223.000000, '5qjccng', 'S', NULL, NULL, NULL, NULL, 750);
INSERT INTO cuenta VALUES ('3526-8802-4949-4634', 5343671.000000, 'rQ9wtTM', 'S', NULL, NULL, NULL, NULL, 301);
INSERT INTO cuenta VALUES ('7664-2611-7081-6632', 9050967.000000, 'b0dOZexCY', 'S', NULL, NULL, NULL, NULL, 16);
INSERT INTO cuenta VALUES ('6541-5717-5729-7113', 3066720.000000, 'C6m6K1f8', 'S', NULL, NULL, NULL, NULL, 14);
INSERT INTO cuenta VALUES ('3372-1461-3357-0143', 8461278.000000, '6qjMkz', 'S', NULL, NULL, NULL, NULL, 586);
INSERT INTO cuenta VALUES ('9689-1520-0552-2257', 6895277.000000, 'ASb7yn1Lhj', 'S', NULL, NULL, NULL, NULL, 752);
INSERT INTO cuenta VALUES ('2802-2131-5201-0271', 5349282.000000, '5tobv8qJWPb', 'S', NULL, NULL, NULL, NULL, 841);
INSERT INTO cuenta VALUES ('5206-5934-1915-3021', 7408733.000000, 'DUFMSOm', 'S', NULL, NULL, NULL, NULL, 695);
INSERT INTO cuenta VALUES ('6491-2184-3317-1931', 4680882.000000, 'OKtvetkLF', 'S', NULL, NULL, NULL, NULL, 627);
INSERT INTO cuenta VALUES ('6635-4746-9618-9316', 6379799.000000, 'K8Qahng69H2', 'S', NULL, NULL, NULL, NULL, 165);
INSERT INTO cuenta VALUES ('3368-0816-3360-9187', 838329.000000, 'SMaIbj1E', 'S', NULL, NULL, NULL, NULL, 517);
INSERT INTO cuenta VALUES ('5428-5398-1935-2463', 8316831.000000, 'uwyyjDS', 'S', NULL, NULL, NULL, NULL, 976);
INSERT INTO cuenta VALUES ('2650-5157-3672-6578', 6116137.000000, 'fV4JjYU05V', 'S', NULL, NULL, NULL, NULL, 185);
INSERT INTO cuenta VALUES ('4192-8466-3559-0834', 5909734.000000, 'vtvVMVqDfaD', 'S', NULL, NULL, NULL, NULL, 421);
INSERT INTO cuenta VALUES ('8203-9351-1310-1235', 8213837.000000, 'S5AWERpk', 'S', NULL, NULL, NULL, NULL, 763);
INSERT INTO cuenta VALUES ('9400-6128-0621-5409', 7630018.000000, 'KhuKs70', 'S', NULL, NULL, NULL, NULL, 186);
INSERT INTO cuenta VALUES ('4119-6950-3561-4992', 7707726.000000, '5U9AGL', 'S', NULL, NULL, NULL, NULL, 336);
INSERT INTO cuenta VALUES ('0346-9608-7387-6327', 5478034.000000, 'B2mExfY', 'S', NULL, NULL, NULL, NULL, 240);
INSERT INTO cuenta VALUES ('5622-1722-7571-8255', 5188260.000000, 'IPSD3ARCWhq', 'S', NULL, NULL, NULL, NULL, 877);
INSERT INTO cuenta VALUES ('8959-5852-1379-0192', 1824497.000000, 'SgiQkyIGfIex', 'S', NULL, NULL, NULL, NULL, 751);
INSERT INTO cuenta VALUES ('6557-7799-9961-8218', 1701425.000000, '6GIPy7Xs', 'S', NULL, NULL, NULL, NULL, 39);
INSERT INTO cuenta VALUES ('0514-4787-8982-4300', 7377228.000000, 'AYx5xcegDi', 'S', NULL, NULL, NULL, NULL, 964);
INSERT INTO cuenta VALUES ('0140-4923-2389-0727', 6072354.000000, 'vhXpbn', 'S', NULL, NULL, NULL, NULL, 461);
INSERT INTO cuenta VALUES ('3780-0383-1667-6535', 3460066.000000, 'LhQrOwhakmj', 'S', NULL, NULL, NULL, NULL, 751);
INSERT INTO cuenta VALUES ('1986-8035-6874-7565', 9557712.000000, '2EB5K2', 'S', NULL, NULL, NULL, NULL, 341);
INSERT INTO cuenta VALUES ('0820-4587-6824-7985', 7781012.000000, 'wBEmZwuZl', 'S', NULL, NULL, NULL, NULL, 230);
INSERT INTO cuenta VALUES ('4452-2795-2853-9523', 2988938.000000, 'nxYO2Si2DQ', 'S', NULL, NULL, NULL, NULL, 381);
INSERT INTO cuenta VALUES ('7401-6719-2903-4065', 468205.000000, '8lPfu3vwL1', 'S', NULL, NULL, NULL, NULL, 412);
INSERT INTO cuenta VALUES ('9363-1099-8826-5566', 6830287.000000, 'uBFK2CR4p', 'S', NULL, NULL, NULL, NULL, 19);
INSERT INTO cuenta VALUES ('1123-4560-6785-9543', 1069090.000000, 'Pvy8UaQ1', 'S', NULL, NULL, NULL, NULL, 387);
INSERT INTO cuenta VALUES ('5551-1019-1170-6548', 3439746.000000, 'w0oM93PG3Sgu', 'S', NULL, NULL, NULL, NULL, 361);
INSERT INTO cuenta VALUES ('6313-3080-5678-3858', 5602739.000000, 'BoPLvS', 'S', NULL, NULL, NULL, NULL, 781);
INSERT INTO cuenta VALUES ('4710-8990-0069-3222', 1058219.000000, 'Ib07Unba', 'S', NULL, NULL, NULL, NULL, 626);
INSERT INTO cuenta VALUES ('1363-2180-8920-1867', 5364487.000000, 'pRpcJZeTagY', 'S', NULL, NULL, NULL, NULL, 992);
INSERT INTO cuenta VALUES ('0181-2541-5255-2584', 695509.000000, 'leilyEBfuN5m', 'S', NULL, NULL, NULL, NULL, 219);
INSERT INTO cuenta VALUES ('7665-4361-2051-0234', 2555003.000000, 'qKVyK93x3aH', 'S', NULL, NULL, NULL, NULL, 245);
INSERT INTO cuenta VALUES ('3671-1051-5487-3782', 2699055.000000, 'VFm7C1vw0PY', 'S', NULL, NULL, NULL, NULL, 75);
INSERT INTO cuenta VALUES ('6424-8071-9108-4502', 2198345.000000, '7ddnWbL', 'S', NULL, NULL, NULL, NULL, 391);
INSERT INTO cuenta VALUES ('7820-4469-0702-7629', 2725605.000000, 'r8o71Z', 'S', NULL, NULL, NULL, NULL, 809);
INSERT INTO cuenta VALUES ('8208-5994-1776-8085', 7475202.000000, 'PESEZvz', 'S', NULL, NULL, NULL, NULL, 631);
INSERT INTO cuenta VALUES ('4981-4577-3614-8588', 4596609.000000, '7ocoSvS', 'S', NULL, NULL, NULL, NULL, 480);
INSERT INTO cuenta VALUES ('7328-1152-9776-2856', 4071866.000000, '6OL6Ti30B', 'S', NULL, NULL, NULL, NULL, 144);
INSERT INTO cuenta VALUES ('5477-1421-8772-8324', 9948390.000000, 'fLA3HOkqX', 'S', NULL, NULL, NULL, NULL, 172);
INSERT INTO cuenta VALUES ('9319-6402-6367-9643', 6277878.000000, 'OqVBP5RmeqT', 'S', NULL, NULL, NULL, NULL, 802);
INSERT INTO cuenta VALUES ('0692-8676-7680-5833', 2773674.000000, 'YLGiduSrUuCz', 'S', NULL, NULL, NULL, NULL, 864);
INSERT INTO cuenta VALUES ('6853-1210-7083-5530', 7551884.000000, '3xAR92c', 'S', NULL, NULL, NULL, NULL, 797);
INSERT INTO cuenta VALUES ('2107-2630-0013-7168', 1002624.000000, 'ea1e8rZ', 'S', NULL, NULL, NULL, NULL, 719);
INSERT INTO cuenta VALUES ('2530-4884-4726-8684', 6048277.000000, 'kFeh4j5ZMDBh', 'S', NULL, NULL, NULL, NULL, 239);
INSERT INTO cuenta VALUES ('9153-0285-9063-5908', 3240566.000000, 'tzwa6boc', 'S', NULL, NULL, NULL, NULL, 818);
INSERT INTO cuenta VALUES ('0074-8367-8071-1220', 5553837.000000, 'QfLHXM6HoaX4', 'S', NULL, NULL, NULL, NULL, 183);
INSERT INTO cuenta VALUES ('0081-7911-8197-5581', 8415198.000000, 'Lk5LP6F', 'S', NULL, NULL, NULL, NULL, 145);
INSERT INTO cuenta VALUES ('2893-6865-7692-8052', 828095.000000, 'SKwCVP3Y', 'S', NULL, NULL, NULL, NULL, 825);
INSERT INTO cuenta VALUES ('8730-6745-7677-0461', 3836571.000000, 'Ng0nCJGri', 'S', NULL, NULL, NULL, NULL, 40);
INSERT INTO cuenta VALUES ('1405-4442-6573-5897', 6602733.000000, 'MIgHYraI', 'S', NULL, NULL, NULL, NULL, 249);
INSERT INTO cuenta VALUES ('1648-0781-3078-1877', 3949843.000000, 'tbZI5wZhVT', 'S', NULL, NULL, NULL, NULL, 603);
INSERT INTO cuenta VALUES ('8309-1029-1985-4355', 553140.000000, 'OKJl66hN5b', 'S', NULL, NULL, NULL, NULL, 914);
INSERT INTO cuenta VALUES ('2221-0754-3973-1051', 1214265.000000, 'd0rUlPt7ksgs', 'S', NULL, NULL, NULL, NULL, 842);
INSERT INTO cuenta VALUES ('4785-7858-5902-0580', 7116745.000000, 'Ftelr8zVTl1j', 'S', NULL, NULL, NULL, NULL, 332);
INSERT INTO cuenta VALUES ('9452-0825-2091-3906', 1533173.000000, '3PPZFAIuEir3', 'S', NULL, NULL, NULL, NULL, 574);
INSERT INTO cuenta VALUES ('7790-6384-6955-0766', 4640132.000000, 'Qw0ePzQ2Gmff', 'S', NULL, NULL, NULL, NULL, 777);
INSERT INTO cuenta VALUES ('2329-7925-9726-5030', 9836660.000000, 'FdXNrBcLg', 'S', NULL, NULL, NULL, NULL, 429);
INSERT INTO cuenta VALUES ('6642-6674-6250-1202', 1294355.000000, 'cZn33VUzCnk', 'S', NULL, NULL, NULL, NULL, 363);
INSERT INTO cuenta VALUES ('3925-5240-3610-2141', 3137387.000000, 'l2EBjGwTMy59', 'S', NULL, NULL, NULL, NULL, 401);
INSERT INTO cuenta VALUES ('6415-4192-3179-9426', 4833540.000000, 'CkVz0lq0VZG3', 'S', NULL, NULL, NULL, NULL, 822);
INSERT INTO cuenta VALUES ('5952-2699-9699-3113', 6713711.000000, 'a5gddw8', 'S', NULL, NULL, NULL, NULL, 261);
INSERT INTO cuenta VALUES ('0841-2249-8886-5338', 2257967.000000, 'KUrGHc4GpHO', 'S', NULL, NULL, NULL, NULL, 234);
INSERT INTO cuenta VALUES ('3304-1266-4460-0809', 2118030.000000, 'vBzufN', 'S', NULL, NULL, NULL, NULL, 845);
INSERT INTO cuenta VALUES ('7591-2485-8429-7497', 3508728.000000, 'Uj6JHb5Wy', 'S', NULL, NULL, NULL, NULL, 104);
INSERT INTO cuenta VALUES ('7872-2526-6619-2504', 2432547.000000, 'ayGkDO', 'S', NULL, NULL, NULL, NULL, 93);
INSERT INTO cuenta VALUES ('8208-5565-5813-1453', 5757745.000000, 'k7uYBkPrX6F', 'S', NULL, NULL, NULL, NULL, 140);
INSERT INTO cuenta VALUES ('6761-5503-3356-1971', 5489694.000000, 'KSyITq', 'S', NULL, NULL, NULL, NULL, 663);
INSERT INTO cuenta VALUES ('9446-5312-0194-9512', 7021216.000000, 'NSWgVI5c', 'S', NULL, NULL, NULL, NULL, 212);
INSERT INTO cuenta VALUES ('4593-9532-3041-7011', 6814095.000000, '1J5reqpgl', 'S', NULL, NULL, NULL, NULL, 808);
INSERT INTO cuenta VALUES ('1373-6024-9204-8582', 2227066.000000, 'yzXSiQLJB', 'S', NULL, NULL, NULL, NULL, 400);
INSERT INTO cuenta VALUES ('9564-8786-5763-0311', 3005797.000000, 'AzzUUNeOslI', 'S', NULL, NULL, NULL, NULL, 552);
INSERT INTO cuenta VALUES ('6889-0041-6232-5724', 1224441.000000, 'uVTwx1nA8', 'S', NULL, NULL, NULL, NULL, 666);
INSERT INTO cuenta VALUES ('4377-0106-3176-8044', 2764135.000000, 'RFos6NaE7Awv', 'S', NULL, NULL, NULL, NULL, 928);
INSERT INTO cuenta VALUES ('0093-0717-7855-8621', 5422427.000000, '6FNBRxF', 'S', NULL, NULL, NULL, NULL, 271);
INSERT INTO cuenta VALUES ('5498-8953-4099-5133', 9763601.000000, 'QDbNmap8WsFA', 'S', NULL, NULL, NULL, NULL, 489);
INSERT INTO cuenta VALUES ('4159-0519-3146-3812', 1142293.000000, 'LSktAu7H6Zi', 'S', NULL, NULL, NULL, NULL, 940);
INSERT INTO cuenta VALUES ('2177-9204-5855-2340', 6073662.000000, 'QuHLAg', 'S', NULL, NULL, NULL, NULL, 295);
INSERT INTO cuenta VALUES ('4408-7236-9916-1891', 7655510.000000, '9Y3o9o6kbSmg', 'S', NULL, NULL, NULL, NULL, 657);
INSERT INTO cuenta VALUES ('0822-7068-9243-8891', 2438446.000000, '24x5s5', 'S', NULL, NULL, NULL, NULL, 61);
INSERT INTO cuenta VALUES ('1780-2902-1963-8625', 7952554.000000, 'b34y1GHz9D', 'S', NULL, NULL, NULL, NULL, 348);
INSERT INTO cuenta VALUES ('9704-9929-7178-8103', 9374397.000000, 'TMG6FGAn', 'S', NULL, NULL, NULL, NULL, 451);
INSERT INTO cuenta VALUES ('1778-8428-8990-5968', 6872511.000000, 'AgdfAoaqmT', 'S', NULL, NULL, NULL, NULL, 81);
INSERT INTO cuenta VALUES ('0177-7899-6206-8106', 4767290.000000, 'ZhRNfJwTT', 'S', NULL, NULL, NULL, NULL, 362);
INSERT INTO cuenta VALUES ('9899-9870-2438-3478', 9648141.000000, '9LXCSp', 'S', NULL, NULL, NULL, NULL, 854);
INSERT INTO cuenta VALUES ('4170-9568-1904-9980', 8210687.000000, 'aCSWxS9QqK', 'S', NULL, NULL, NULL, NULL, 304);
INSERT INTO cuenta VALUES ('9827-9591-6662-0112', 6143477.000000, 'Il0uCv', 'S', NULL, NULL, NULL, NULL, 366);
INSERT INTO cuenta VALUES ('9409-0563-8504-7287', 4378424.000000, 'AekT8yM14', 'S', NULL, NULL, NULL, NULL, 386);
INSERT INTO cuenta VALUES ('9811-1722-5045-0670', 8876900.000000, 'idj4aiwy', 'S', NULL, NULL, NULL, NULL, 402);
INSERT INTO cuenta VALUES ('9350-0086-1238-0376', 4791794.000000, '2xAckpDz', 'S', NULL, NULL, NULL, NULL, 87);
INSERT INTO cuenta VALUES ('3605-7164-4531-3983', 1549819.000000, 'OyGel2B2bFW', 'S', NULL, NULL, NULL, NULL, 858);
INSERT INTO cuenta VALUES ('2387-4116-3699-0044', 5281618.000000, 'obyomBAhwLo', 'S', NULL, NULL, NULL, NULL, 857);
INSERT INTO cuenta VALUES ('4327-3699-3991-5248', 5184968.000000, 'uAwQEIYlrQ0', 'S', NULL, NULL, NULL, NULL, 296);
INSERT INTO cuenta VALUES ('8057-8052-0967-7029', 3119053.000000, 'NGoaj21p', 'S', NULL, NULL, NULL, NULL, 177);
INSERT INTO cuenta VALUES ('2125-2796-8386-1777', 4239530.000000, 'JpoVTPW00NA', 'S', NULL, NULL, NULL, NULL, 690);
INSERT INTO cuenta VALUES ('7111-5132-7995-5089', 2993507.000000, 'MOXLXtxASHhb', 'S', NULL, NULL, NULL, NULL, 539);
INSERT INTO cuenta VALUES ('4305-2519-0729-1255', 423424.000000, '5lvoaA', 'S', NULL, NULL, NULL, NULL, 215);
INSERT INTO cuenta VALUES ('2819-7576-2967-7617', 4123586.000000, 'XSVHeirBU', 'S', NULL, NULL, NULL, NULL, 432);
INSERT INTO cuenta VALUES ('7600-5534-7912-7650', 8520391.000000, 'CWGZURyKOzD', 'S', NULL, NULL, NULL, NULL, 271);
INSERT INTO cuenta VALUES ('0031-0825-4207-7451', 3764919.000000, 'SWXNjZJIrmQ', 'S', NULL, NULL, NULL, NULL, 337);
INSERT INTO cuenta VALUES ('9494-1375-9599-2451', 6593574.000000, 'hm8MjFsG', 'S', NULL, NULL, NULL, NULL, 760);
INSERT INTO cuenta VALUES ('7785-2013-9754-1083', 2144300.000000, 'VxI6LjC', 'S', NULL, NULL, NULL, NULL, 710);
INSERT INTO cuenta VALUES ('6690-3842-6103-9519', 8141612.000000, 'YZLw1tNofFW', 'S', NULL, NULL, NULL, NULL, 786);
INSERT INTO cuenta VALUES ('2639-9433-6813-5967', 8469561.000000, 'Dnqp7rf1AZ', 'S', NULL, NULL, NULL, NULL, 661);
INSERT INTO cuenta VALUES ('6646-0588-6217-9747', 473546.000000, '6NwEP8smjnV', 'S', NULL, NULL, NULL, NULL, 457);
INSERT INTO cuenta VALUES ('6549-6805-4081-8635', 9675857.000000, 'J0hSTOHQXug', 'S', NULL, NULL, NULL, NULL, 247);
INSERT INTO cuenta VALUES ('8004-0166-8784-4683', 1517521.000000, 'CGZEHIpuI', 'S', NULL, NULL, NULL, NULL, 774);
INSERT INTO cuenta VALUES ('8881-4291-1393-9206', 2342315.000000, 'KxQuu3wDDQi6', 'S', NULL, NULL, NULL, NULL, 196);
INSERT INTO cuenta VALUES ('1628-4469-4254-4255', 5726021.000000, 'N8HOKXqxaW', 'S', NULL, NULL, NULL, NULL, 406);
INSERT INTO cuenta VALUES ('8552-0405-6197-9901', 9051464.000000, 'TAzoON5k', 'S', NULL, NULL, NULL, NULL, 583);
INSERT INTO cuenta VALUES ('9883-5961-6517-4010', 352241.000000, 'LWMqQQfWHp52', 'S', NULL, NULL, NULL, NULL, 347);
INSERT INTO cuenta VALUES ('3084-3732-4361-0086', 9394998.000000, 'gmNsj6fovxOS', 'S', NULL, NULL, NULL, NULL, 535);
INSERT INTO cuenta VALUES ('0746-0674-7223-5619', 3317560.000000, 'k58Fuo', 'S', NULL, NULL, NULL, NULL, 70);
INSERT INTO cuenta VALUES ('2280-1779-0471-5318', 7721689.000000, 'QhSMQt3p', 'S', NULL, NULL, NULL, NULL, 734);
INSERT INTO cuenta VALUES ('5545-1357-9636-3169', 7535825.000000, 'IOGKyBZil', 'S', NULL, NULL, NULL, NULL, 218);
INSERT INTO cuenta VALUES ('3583-8213-4143-9711', 1659583.000000, 'HNrpKzYrq', 'S', NULL, NULL, NULL, NULL, 520);
INSERT INTO cuenta VALUES ('5081-7006-2463-0217', 7372389.000000, 'aert3tcLJ', 'S', NULL, NULL, NULL, NULL, 353);
INSERT INTO cuenta VALUES ('0625-5789-0933-9728', 2341932.000000, 'HV52R5', 'S', NULL, NULL, NULL, NULL, 702);
INSERT INTO cuenta VALUES ('0140-2787-6477-4524', 7429465.000000, 'POKqPpHmjb2', 'S', NULL, NULL, NULL, NULL, 874);
INSERT INTO cuenta VALUES ('4821-3301-7746-1349', 3888576.000000, 'F5iv5u', 'S', NULL, NULL, NULL, NULL, 357);
INSERT INTO cuenta VALUES ('9606-1585-2060-8079', 3875814.000000, '1KMb52TV5a', 'S', NULL, NULL, NULL, NULL, 238);
INSERT INTO cuenta VALUES ('5467-3923-1765-7151', 1295676.000000, 'Yel9fgbtv', 'S', NULL, NULL, NULL, NULL, 624);
INSERT INTO cuenta VALUES ('0097-7698-8413-7348', 1809074.000000, 'hYwiUE', 'S', NULL, NULL, NULL, NULL, 648);
INSERT INTO cuenta VALUES ('1508-2064-2026-7610', 3714680.000000, 'hxNLKAPsdJ', 'S', NULL, NULL, NULL, NULL, 407);
INSERT INTO cuenta VALUES ('0276-7149-2926-4746', 8847541.000000, '7dsZ9OKApI', 'S', NULL, NULL, NULL, NULL, 147);
INSERT INTO cuenta VALUES ('5345-1932-3298-5325', 9687776.000000, 'CyrUx6P9OPZE', 'S', NULL, NULL, NULL, NULL, 297);
INSERT INTO cuenta VALUES ('6387-3084-2819-5638', 9242532.000000, 'nwo3Eulcj', 'S', NULL, NULL, NULL, NULL, 391);
INSERT INTO cuenta VALUES ('2374-2534-7359-2444', 5677040.000000, 'OQ8L7i', 'S', NULL, NULL, NULL, NULL, 321);
INSERT INTO cuenta VALUES ('8263-6894-0909-0911', 2053960.000000, 'SzuW3N2rz', 'S', NULL, NULL, NULL, NULL, 47);
INSERT INTO cuenta VALUES ('3376-3270-3265-3518', 3119340.000000, 'WkIBEyGHBm6', 'S', NULL, NULL, NULL, NULL, 404);
INSERT INTO cuenta VALUES ('6941-1137-1293-6653', 9257205.000000, 'k2c6ZALJOI', 'S', NULL, NULL, NULL, NULL, 287);
INSERT INTO cuenta VALUES ('0075-6185-1037-6321', 6993787.000000, '93FIv1KWH', 'S', NULL, NULL, NULL, NULL, 663);
INSERT INTO cuenta VALUES ('1100-7332-6663-8295', 8734260.000000, 'oyAWKtJB', 'S', NULL, NULL, NULL, NULL, 684);
INSERT INTO cuenta VALUES ('8580-4430-7584-2750', 2473264.000000, 'QML1fd6oA', 'S', NULL, NULL, NULL, NULL, 308);
INSERT INTO cuenta VALUES ('9392-5951-1261-6862', 9990606.000000, 'IgTNQo9', 'S', NULL, NULL, NULL, NULL, 659);
INSERT INTO cuenta VALUES ('6208-3887-9872-0419', 3785086.000000, 'R4jjsTo', 'S', NULL, NULL, NULL, NULL, 462);
INSERT INTO cuenta VALUES ('5998-1286-0435-2887', 280557.000000, 'Ww5aFJwWv', 'S', NULL, NULL, NULL, NULL, 188);
INSERT INTO cuenta VALUES ('8722-1029-6046-2103', 345649.000000, 'NYBp2b2svU', 'S', NULL, NULL, NULL, NULL, 231);
INSERT INTO cuenta VALUES ('6876-3354-5583-1458', 8646179.000000, 'awbKX7NOiA', 'S', NULL, NULL, NULL, NULL, 805);
INSERT INTO cuenta VALUES ('3915-5119-8398-0697', 9178815.000000, 'p77LIRq9ggq', 'S', NULL, NULL, NULL, NULL, 37);
INSERT INTO cuenta VALUES ('6879-9953-6602-9061', 8968819.000000, 'U4pMIxPmjcMp', 'S', NULL, NULL, NULL, NULL, 936);
INSERT INTO cuenta VALUES ('2998-6007-0135-7091', 9686207.000000, 'M8zhIM0Be', 'S', NULL, NULL, NULL, NULL, 418);
INSERT INTO cuenta VALUES ('7016-8978-9924-1613', 2483718.000000, 'wl1xfgcqmE', 'S', NULL, NULL, NULL, NULL, 330);
INSERT INTO cuenta VALUES ('3535-2449-5558-7697', 1795218.000000, 'BLdcRXJul', 'S', NULL, NULL, NULL, NULL, 379);
INSERT INTO cuenta VALUES ('8000-2272-1003-6653', 8843769.000000, 'u9xWb6WnEi', 'S', NULL, NULL, NULL, NULL, 922);
INSERT INTO cuenta VALUES ('0941-9567-9911-0938', 6039488.000000, 'aZTHlFPdco', 'S', NULL, NULL, NULL, NULL, 369);
INSERT INTO cuenta VALUES ('9865-7398-8744-4357', 7417640.000000, 'mGnFsdH6O87', 'S', NULL, NULL, NULL, NULL, 496);
INSERT INTO cuenta VALUES ('4348-8697-9298-2108', 570761.000000, 'LpdMtBo', 'S', NULL, NULL, NULL, NULL, 141);
INSERT INTO cuenta VALUES ('6953-0000-0012-2654', 1284064.000000, '1Rl91m14WC6', 'S', NULL, NULL, NULL, NULL, 694);
INSERT INTO cuenta VALUES ('9372-1718-0849-8844', 3091682.000000, 'WMLorXn', 'S', NULL, NULL, NULL, NULL, 568);
INSERT INTO cuenta VALUES ('5374-2352-9131-4756', 6456914.000000, 'gtwIar0H', 'S', NULL, NULL, NULL, NULL, 406);
INSERT INTO cuenta VALUES ('4490-3980-7238-8700', 8409651.000000, 'BfZLzqe8rn', 'S', NULL, NULL, NULL, NULL, 542);
INSERT INTO cuenta VALUES ('4759-7971-8874-1491', 5500290.000000, 'ugmf0vgjKRAn', 'S', NULL, NULL, NULL, NULL, 328);
INSERT INTO cuenta VALUES ('5414-2120-4147-4860', 6112918.000000, 'z9IJmua6NO8', 'S', NULL, NULL, NULL, NULL, 826);
INSERT INTO cuenta VALUES ('6771-5490-2874-7421', 6079960.000000, 't52ooe', 'S', NULL, NULL, NULL, NULL, 301);
INSERT INTO cuenta VALUES ('6130-3140-1930-7167', 4243261.000000, 'p86Tnj', 'S', NULL, NULL, NULL, NULL, 984);
INSERT INTO cuenta VALUES ('7671-7317-0267-7964', 1711268.000000, '6Z0glvpsBU7', 'S', NULL, NULL, NULL, NULL, 272);
INSERT INTO cuenta VALUES ('1679-2509-6968-7377', 6653811.000000, 'BBdPOx', 'S', NULL, NULL, NULL, NULL, 979);
INSERT INTO cuenta VALUES ('7366-7385-3876-8415', 5036981.000000, 'nCIRbDGIAyY', 'S', NULL, NULL, NULL, NULL, 572);
INSERT INTO cuenta VALUES ('6735-0858-7744-7994', 7755468.000000, 'Zjkv7PdxLM96', 'S', NULL, NULL, NULL, NULL, 689);
INSERT INTO cuenta VALUES ('9047-7506-0162-0489', 1197668.000000, 'gpjZQP17G', 'S', NULL, NULL, NULL, NULL, 26);
INSERT INTO cuenta VALUES ('7881-2895-3447-1545', 7682160.000000, 'I5SeDLB1So', 'S', NULL, NULL, NULL, NULL, 811);
INSERT INTO cuenta VALUES ('1244-3751-3519-7016', 5246807.000000, 'XHUThIL42', 'S', NULL, NULL, NULL, NULL, 507);
INSERT INTO cuenta VALUES ('7800-5498-7867-5837', 7026507.000000, 'IS4Mny75', 'S', NULL, NULL, NULL, NULL, 865);
INSERT INTO cuenta VALUES ('1218-5597-4263-9081', 3672774.000000, 'KBzPnDwpn', 'S', NULL, NULL, NULL, NULL, 89);
INSERT INTO cuenta VALUES ('5123-5612-7316-1987', 9212133.000000, 'YDtmQbGxP2', 'S', NULL, NULL, NULL, NULL, 955);
INSERT INTO cuenta VALUES ('0605-9991-1349-8896', 9689823.000000, '07FDUOGy', 'S', NULL, NULL, NULL, NULL, 913);
INSERT INTO cuenta VALUES ('6024-2414-7844-5037', 1257159.000000, 'yOvaI3i0', 'S', NULL, NULL, NULL, NULL, 568);
INSERT INTO cuenta VALUES ('3564-5733-3113-4933', 5132014.000000, '3Epkr0Vx', 'S', NULL, NULL, NULL, NULL, 398);
INSERT INTO cuenta VALUES ('3163-6133-3780-5137', 1752841.000000, 'qjBVVqLsg9tb', 'S', NULL, NULL, NULL, NULL, 442);
INSERT INTO cuenta VALUES ('7629-4189-1211-5218', 6332280.000000, 'nylFfXzKET', 'S', NULL, NULL, NULL, NULL, 442);
INSERT INTO cuenta VALUES ('2370-4863-9564-5049', 4435834.000000, '19DOQfB', 'S', NULL, NULL, NULL, NULL, 493);
INSERT INTO cuenta VALUES ('6703-6438-5781-3618', 1778215.000000, '9mKnqom3PC', 'S', NULL, NULL, NULL, NULL, 413);
INSERT INTO cuenta VALUES ('9512-2858-0859-3287', 6313597.000000, 'LOPpf7MjIgL', 'S', NULL, NULL, NULL, NULL, 909);
INSERT INTO cuenta VALUES ('7168-3838-8848-0614', 4294121.000000, '8NA7db7', 'S', NULL, NULL, NULL, NULL, 312);
INSERT INTO cuenta VALUES ('2425-7395-8704-0178', 4777592.000000, 'onFhhxVr', 'S', NULL, NULL, NULL, NULL, 531);
INSERT INTO cuenta VALUES ('3118-9370-9608-0660', 7622809.000000, 'cUfeZ2uoM3d', 'S', NULL, NULL, NULL, NULL, 733);
INSERT INTO cuenta VALUES ('0714-1131-7491-7867', 5378184.000000, 'KLJ5RDS', 'S', NULL, NULL, NULL, NULL, 26);
INSERT INTO cuenta VALUES ('3787-9057-2673-4768', 2040734.000000, 'GiVHbz', 'S', NULL, NULL, NULL, NULL, 505);
INSERT INTO cuenta VALUES ('6926-2835-3378-2241', 2703198.000000, 'DbePq4j', 'S', NULL, NULL, NULL, NULL, 240);
INSERT INTO cuenta VALUES ('6927-8165-6542-7138', 5235323.000000, 'MdI8qd', 'S', NULL, NULL, NULL, NULL, 344);
INSERT INTO cuenta VALUES ('6288-7006-5475-6661', 2463851.000000, 'PYOM95h', 'S', NULL, NULL, NULL, NULL, 200);
INSERT INTO cuenta VALUES ('1832-9622-2825-4224', 6564169.000000, '5n6G4PydXi', 'S', NULL, NULL, NULL, NULL, 72);
INSERT INTO cuenta VALUES ('1232-4421-2594-5281', 6473550.000000, 'KwMvAK', 'S', NULL, NULL, NULL, NULL, 337);
INSERT INTO cuenta VALUES ('1486-3459-0435-3155', 491048.000000, 'DvG6e4BM', 'S', NULL, NULL, NULL, NULL, 751);
INSERT INTO cuenta VALUES ('8910-8488-8040-7169', 5494578.000000, 'p5zZC8', 'S', NULL, NULL, NULL, NULL, 498);
INSERT INTO cuenta VALUES ('6243-5359-5834-3643', 1236149.000000, 'qh5Khs', 'S', NULL, NULL, NULL, NULL, 756);
INSERT INTO cuenta VALUES ('3349-8388-9044-8651', 7253932.000000, '4U7YdONZ', 'S', NULL, NULL, NULL, NULL, 969);
INSERT INTO cuenta VALUES ('3030-5344-0883-5346', 7918822.000000, 'RSaqHJE0SqT', 'S', NULL, NULL, NULL, NULL, 808);
INSERT INTO cuenta VALUES ('3652-8402-2084-3744', 5652049.000000, 'nngRZyz0k', 'S', NULL, NULL, NULL, NULL, 15);
INSERT INTO cuenta VALUES ('1283-8610-4212-9730', 4033185.000000, 'EpTYfO', 'S', NULL, NULL, NULL, NULL, 54);
INSERT INTO cuenta VALUES ('9634-2056-2795-7015', 918800.000000, '2zc1pKkx1p', 'S', NULL, NULL, NULL, NULL, 877);
INSERT INTO cuenta VALUES ('5092-0727-0054-6347', 1765270.000000, 'RQvItj', 'S', NULL, NULL, NULL, NULL, 957);
INSERT INTO cuenta VALUES ('7589-0471-6735-5401', 3992030.000000, 'Wgdb91P', 'S', NULL, NULL, NULL, NULL, 965);
INSERT INTO cuenta VALUES ('7327-6841-6103-5107', 3210975.000000, 'vPJl5zMxyfG', 'S', NULL, NULL, NULL, NULL, 455);
INSERT INTO cuenta VALUES ('7998-0816-9249-5992', 9538823.000000, 'LfrAe9BM8', 'S', NULL, NULL, NULL, NULL, 707);
INSERT INTO cuenta VALUES ('9156-2306-0183-0385', 6287645.000000, '4PX7wWl7', 'S', NULL, NULL, NULL, NULL, 152);
INSERT INTO cuenta VALUES ('2379-6060-8267-7139', 3817679.000000, 'WTHSI5ARFR', 'S', NULL, NULL, NULL, NULL, 627);
INSERT INTO cuenta VALUES ('1772-4265-0104-8486', 577033.000000, 'WX0VDscBzEB', 'S', NULL, NULL, NULL, NULL, 458);
INSERT INTO cuenta VALUES ('5835-9233-7689-1111', 9848036.000000, '8MdYkMJrfj7A', 'S', NULL, NULL, NULL, NULL, 269);
INSERT INTO cuenta VALUES ('2109-5322-2196-3482', 1397681.000000, 'erFf2GOJarka', 'S', NULL, NULL, NULL, NULL, 585);
INSERT INTO cuenta VALUES ('8602-7362-1082-6366', 9050003.000000, 'gA1IdEYxwt9', 'S', NULL, NULL, NULL, NULL, 228);
INSERT INTO cuenta VALUES ('6576-6280-8889-9108', 1768684.000000, 'fbQHbubptfE', 'S', NULL, NULL, NULL, NULL, 980);
INSERT INTO cuenta VALUES ('7056-7918-1988-2836', 1394321.000000, '9882GJRR5', 'S', NULL, NULL, NULL, NULL, 670);
INSERT INTO cuenta VALUES ('4709-7969-4885-5187', 6814123.000000, 'yE06NA7thMgM', 'S', NULL, NULL, NULL, NULL, 480);
INSERT INTO cuenta VALUES ('8327-1459-3640-6015', 9995315.000000, 'O4nLoK6zdO', 'S', NULL, NULL, NULL, NULL, 328);
INSERT INTO cuenta VALUES ('9261-3382-3016-6082', 658788.000000, 'vUkA3cH', 'S', NULL, NULL, NULL, NULL, 135);
INSERT INTO cuenta VALUES ('2491-7738-6169-4478', 1060089.000000, 'YTJfGluB', 'S', NULL, NULL, NULL, NULL, 444);
INSERT INTO cuenta VALUES ('2543-2609-9528-0688', 361604.000000, 'Bs1xZ5i5w', 'S', NULL, NULL, NULL, NULL, 303);
INSERT INTO cuenta VALUES ('0077-8382-6894-1833', 8007827.000000, 'YGDvl6FW8oou', 'S', NULL, NULL, NULL, NULL, 189);
INSERT INTO cuenta VALUES ('6186-9891-1392-0544', 7854793.000000, 'tBUKLZ9', 'S', NULL, NULL, NULL, NULL, 510);
INSERT INTO cuenta VALUES ('0207-6599-6207-7293', 7238415.000000, 'TTlnV1X', 'S', NULL, NULL, NULL, NULL, 673);
INSERT INTO cuenta VALUES ('6847-4825-8553-5681', 633023.000000, 'StutzqOKp', 'S', NULL, NULL, NULL, NULL, 793);
INSERT INTO cuenta VALUES ('7786-2488-0114-3528', 7735289.000000, 'CpwdaTsnt', 'S', NULL, NULL, NULL, NULL, 763);
INSERT INTO cuenta VALUES ('1293-6124-3978-4095', 6757908.000000, 'CtMuYHq', 'S', NULL, NULL, NULL, NULL, 104);
INSERT INTO cuenta VALUES ('6555-6816-0646-2682', 5974291.000000, '6VaD85', 'S', NULL, NULL, NULL, NULL, 707);
INSERT INTO cuenta VALUES ('9924-9845-7043-6223', 7987446.000000, 'CL7RvSEHG6B', 'S', NULL, NULL, NULL, NULL, 374);
INSERT INTO cuenta VALUES ('7923-5977-0907-5796', 1915202.000000, 'oIRc2VoA', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO cuenta VALUES ('0560-4661-1372-3656', 8010007.000000, 'oqUp76iJUK', 'S', NULL, NULL, NULL, NULL, 180);
INSERT INTO cuenta VALUES ('5500-1286-3789-0175', 3721076.000000, 'FwoMrb3ukch5', 'S', NULL, NULL, NULL, NULL, 116);
INSERT INTO cuenta VALUES ('2612-5828-0172-4289', 9787315.000000, 'WEn3aVJ', 'S', NULL, NULL, NULL, NULL, 821);
INSERT INTO cuenta VALUES ('4990-7591-5046-9079', 2623003.000000, 'iXSfqP', 'S', NULL, NULL, NULL, NULL, 181);
INSERT INTO cuenta VALUES ('0684-6111-7709-1157', 860744.000000, 'SeiulWCmeM', 'S', NULL, NULL, NULL, NULL, 996);
INSERT INTO cuenta VALUES ('0303-9744-5598-1034', 5212153.000000, 'rBHlBe9xDKG', 'S', NULL, NULL, NULL, NULL, 467);
INSERT INTO cuenta VALUES ('1143-1930-0572-7289', 361983.000000, 'cUVuF0fjL', 'S', NULL, NULL, NULL, NULL, 458);
INSERT INTO cuenta VALUES ('5213-1946-6403-3553', 3739934.000000, 'xH5CBLEOkuwh', 'S', NULL, NULL, NULL, NULL, 307);
INSERT INTO cuenta VALUES ('5832-6937-3216-6329', 7582395.000000, 'Irncip', 'S', NULL, NULL, NULL, NULL, 203);
INSERT INTO cuenta VALUES ('9218-1566-1068-6049', 3089460.000000, 'ag67CI4hcgL0', 'S', NULL, NULL, NULL, NULL, 154);
INSERT INTO cuenta VALUES ('8711-8195-4783-1092', 8022074.000000, 'hNuPJ9vk7Pz', 'S', NULL, NULL, NULL, NULL, 153);
INSERT INTO cuenta VALUES ('3232-3396-8859-4945', 406565.000000, 'TGkIyE53eCD', 'S', NULL, NULL, NULL, NULL, 530);
INSERT INTO cuenta VALUES ('4551-2589-7606-5608', 4598201.000000, 'OpkWOi', 'S', NULL, NULL, NULL, NULL, 339);
INSERT INTO cuenta VALUES ('0798-4948-4656-4453', 7037974.000000, 'M44hHN', 'S', NULL, NULL, NULL, NULL, 184);
INSERT INTO cuenta VALUES ('8284-5047-3214-2991', 8310614.000000, 'E8O1Z2xvZG', 'S', NULL, NULL, NULL, NULL, 364);
INSERT INTO cuenta VALUES ('3891-5908-7556-6405', 6614813.000000, 'iMctlbKSjP5', 'S', NULL, NULL, NULL, NULL, 558);
INSERT INTO cuenta VALUES ('8950-2285-5040-4032', 1133219.000000, 'oQontcDF88', 'S', NULL, NULL, NULL, NULL, 82);
INSERT INTO cuenta VALUES ('5166-2374-5347-4160', 2114073.000000, 'XfymcaxOX', 'S', NULL, NULL, NULL, NULL, 486);
INSERT INTO cuenta VALUES ('0495-0274-6737-9516', 1179187.000000, 'rEElcCce', 'S', NULL, NULL, NULL, NULL, 949);
INSERT INTO cuenta VALUES ('2792-9059-5930-6484', 2655609.000000, 'XyKbbO', 'S', NULL, NULL, NULL, NULL, 78);
INSERT INTO cuenta VALUES ('3897-2818-7764-7654', 9370293.000000, '7kJ7ob', 'S', NULL, NULL, NULL, NULL, 265);
INSERT INTO cuenta VALUES ('8728-0284-9812-6524', 5941874.000000, 'Tjp82cIFC2', 'S', NULL, NULL, NULL, NULL, 569);
INSERT INTO cuenta VALUES ('1810-2868-6592-1860', 4094035.000000, '5yLlEk', 'S', NULL, NULL, NULL, NULL, 934);
INSERT INTO cuenta VALUES ('2226-7529-2167-0371', 1805689.000000, 'nIDlxj', 'S', NULL, NULL, NULL, NULL, 664);
INSERT INTO cuenta VALUES ('2864-4811-5832-3298', 3654581.000000, 'CdBaJGixqwW', 'S', NULL, NULL, NULL, NULL, 418);
INSERT INTO cuenta VALUES ('0519-8443-6363-4791', 2665267.000000, 'flJsTGbsK', 'S', NULL, NULL, NULL, NULL, 465);
INSERT INTO cuenta VALUES ('5568-2696-5810-0516', 1479547.000000, 'YCGarf', 'S', NULL, NULL, NULL, NULL, 90);
INSERT INTO cuenta VALUES ('6904-6818-2252-3788', 6882568.000000, 'roOO5b5auFwX', 'S', NULL, NULL, NULL, NULL, 284);
INSERT INTO cuenta VALUES ('8438-2972-3579-8814', 4255440.000000, 'lMwq3fl', 'S', NULL, NULL, NULL, NULL, 531);
INSERT INTO cuenta VALUES ('2705-5302-1866-9530', 5869160.000000, '93s4AG0kIIHC', 'S', NULL, NULL, NULL, NULL, 820);
INSERT INTO cuenta VALUES ('8351-7638-6418-0664', 1957564.000000, 'ZU6jkxJ25', 'S', NULL, NULL, NULL, NULL, 45);
INSERT INTO cuenta VALUES ('2952-6640-6879-5318', 821341.000000, 'EMTfx5isVef', 'S', NULL, NULL, NULL, NULL, 584);
INSERT INTO cuenta VALUES ('9955-6247-5740-6265', 7663985.000000, 'kyrcXozE0', 'S', NULL, NULL, NULL, NULL, 800);
INSERT INTO cuenta VALUES ('1006-8363-7959-5345', 9503867.000000, 'BMIhMH', 'S', NULL, NULL, NULL, NULL, 198);
INSERT INTO cuenta VALUES ('4152-6436-1853-4550', 5857230.000000, 'qI2EnmaP', 'S', NULL, NULL, NULL, NULL, 241);
INSERT INTO cuenta VALUES ('8192-2341-2023-3195', 9836476.000000, '6ImO8RjR', 'S', NULL, NULL, NULL, NULL, 533);
INSERT INTO cuenta VALUES ('5146-4727-1765-5050', 7878887.000000, 'FPcZ2bIgYg', 'S', NULL, NULL, NULL, NULL, 998);
INSERT INTO cuenta VALUES ('1212-1898-2182-5009', 3364708.000000, '20F4vJ9yD', 'S', NULL, NULL, NULL, NULL, 99);
INSERT INTO cuenta VALUES ('4469-1115-0179-3752', 8222538.000000, 'rWL056', 'S', NULL, NULL, NULL, NULL, 91);
INSERT INTO cuenta VALUES ('3578-5937-5577-4200', 526075.000000, 'SNYRH7', 'S', NULL, NULL, NULL, NULL, 903);
INSERT INTO cuenta VALUES ('7603-4214-2216-1711', 3692527.000000, 'ApJ8mX', 'S', NULL, NULL, NULL, NULL, 625);
INSERT INTO cuenta VALUES ('3231-5665-9336-4930', 4421481.000000, 'AqxtxHR', 'S', NULL, NULL, NULL, NULL, 158);
INSERT INTO cuenta VALUES ('5706-5268-7517-7328', 9333209.000000, '3arallLd', 'S', NULL, NULL, NULL, NULL, 314);
INSERT INTO cuenta VALUES ('0500-8267-0385-3204', 6056629.000000, '7aIWDQ7hR', 'S', NULL, NULL, NULL, NULL, 290);
INSERT INTO cuenta VALUES ('4041-1655-5923-0729', 2545448.000000, 'OlyYpf033b', 'S', NULL, NULL, NULL, NULL, 792);
INSERT INTO cuenta VALUES ('8376-7939-9428-9693', 9865504.000000, 'QuuXhb2CWaxY', 'S', NULL, NULL, NULL, NULL, 274);
INSERT INTO cuenta VALUES ('6669-0305-6209-5818', 5318450.000000, 'lyRiJRWkShCB', 'S', NULL, NULL, NULL, NULL, 74);
INSERT INTO cuenta VALUES ('9191-8786-5106-0667', 5849272.000000, 'fuM7CW', 'S', NULL, NULL, NULL, NULL, 418);
INSERT INTO cuenta VALUES ('6949-2008-3748-8577', 6815315.000000, 'XdRRhxSfyM', 'S', NULL, NULL, NULL, NULL, 57);
INSERT INTO cuenta VALUES ('1895-4646-2215-5779', 5963296.000000, 'eoYz0x', 'S', NULL, NULL, NULL, NULL, 873);
INSERT INTO cuenta VALUES ('3938-0252-3933-7528', 4911901.000000, 'eAncjvN', 'S', NULL, NULL, NULL, NULL, 886);
INSERT INTO cuenta VALUES ('5255-9094-5380-8858', 4258730.000000, 'jPKXiES', 'S', NULL, NULL, NULL, NULL, 776);
INSERT INTO cuenta VALUES ('7213-3694-2680-3233', 865292.000000, 'WORPo8K2', 'S', NULL, NULL, NULL, NULL, 77);
INSERT INTO cuenta VALUES ('5063-8232-6239-0150', 1296390.000000, 'CaLfmRaaY', 'S', NULL, NULL, NULL, NULL, 528);
INSERT INTO cuenta VALUES ('6914-6780-2252-4531', 8033083.000000, 'fSh32V', 'S', NULL, NULL, NULL, NULL, 493);
INSERT INTO cuenta VALUES ('9237-4423-9181-6079', 607724.000000, 'x6o3ABgc', 'S', NULL, NULL, NULL, NULL, 646);
INSERT INTO cuenta VALUES ('6846-6981-4048-7296', 468781.000000, 'CoVCT2j', 'S', NULL, NULL, NULL, NULL, 316);
INSERT INTO cuenta VALUES ('8970-0470-8363-0744', 6892145.000000, 'm6CRKQsYoBFk', 'S', NULL, NULL, NULL, NULL, 75);
INSERT INTO cuenta VALUES ('1259-1754-5933-9904', 9524244.000000, 'XcZKm3X', 'S', NULL, NULL, NULL, NULL, 496);
INSERT INTO cuenta VALUES ('6736-4528-6431-4990', 5618955.000000, 'ldJ6el', 'S', NULL, NULL, NULL, NULL, 957);
INSERT INTO cuenta VALUES ('9603-6566-4780-2484', 9608301.000000, '9aPcohJJDs', 'S', NULL, NULL, NULL, NULL, 21);
INSERT INTO cuenta VALUES ('4303-2080-5179-6157', 6348335.000000, 'x34je0', 'S', NULL, NULL, NULL, NULL, 754);
INSERT INTO cuenta VALUES ('0026-2816-9564-1013', 2537978.000000, 'NOotEfXbBXkV', 'S', NULL, NULL, NULL, NULL, 596);
INSERT INTO cuenta VALUES ('2437-1576-3404-9908', 8776991.000000, 'AU8ryriTTeT4', 'S', NULL, NULL, NULL, NULL, 196);
INSERT INTO cuenta VALUES ('7644-6681-1066-9493', 4815748.000000, '6onupD', 'S', NULL, NULL, NULL, NULL, 108);
INSERT INTO cuenta VALUES ('9027-9750-8145-5379', 6138140.000000, 'ihEtkEbeD', 'S', NULL, NULL, NULL, NULL, 543);
INSERT INTO cuenta VALUES ('8029-3357-1321-2734', 6291010.000000, 'Ol1EFB8Od', 'S', NULL, NULL, NULL, NULL, 944);
INSERT INTO cuenta VALUES ('8447-8591-4374-9287', 992680.000000, 'sAeQLBewKUDk', 'S', NULL, NULL, NULL, NULL, 139);
INSERT INTO cuenta VALUES ('9956-5857-4936-7706', 1674825.000000, '4h9OGiSEgfcz', 'S', NULL, NULL, NULL, NULL, 476);
INSERT INTO cuenta VALUES ('7029-1545-0892-4400', 5980089.000000, '2VRNJU', 'S', NULL, NULL, NULL, NULL, 809);
INSERT INTO cuenta VALUES ('7668-8112-2077-8420', 4208974.000000, 'rEzU65ZqzH', 'S', NULL, NULL, NULL, NULL, 851);
INSERT INTO cuenta VALUES ('4100-6594-6717-1670', 3757369.000000, 'r8VkVcry4', 'S', NULL, NULL, NULL, NULL, 468);
INSERT INTO cuenta VALUES ('0947-0978-6525-5862', 5322072.000000, '9pmMbH7eH', 'S', NULL, NULL, NULL, NULL, 127);
INSERT INTO cuenta VALUES ('5461-3866-0547-6212', 7698412.000000, 'jveP4uTm', 'S', NULL, NULL, NULL, NULL, 972);
INSERT INTO cuenta VALUES ('3779-1660-9901-5439', 828523.000000, 'grNIp7yAhr', 'S', NULL, NULL, NULL, NULL, 224);
INSERT INTO cuenta VALUES ('3202-8785-7610-1620', 2282162.000000, 'O2Rw8Ka', 'S', NULL, NULL, NULL, NULL, 687);
INSERT INTO cuenta VALUES ('7634-2860-1941-8213', 7165905.000000, 'RWh8WwENv', 'S', NULL, NULL, NULL, NULL, 284);
INSERT INTO cuenta VALUES ('8255-9599-2397-2235', 466504.000000, 'KxMfTESS', 'S', NULL, NULL, NULL, NULL, 881);
INSERT INTO cuenta VALUES ('2691-9297-6444-7373', 4169114.000000, 'kgApB2bLOuq', 'S', NULL, NULL, NULL, NULL, 221);
INSERT INTO cuenta VALUES ('7553-1142-5366-4335', 5542647.000000, 'FKJESR', 'S', NULL, NULL, NULL, NULL, 525);
INSERT INTO cuenta VALUES ('4314-0768-0987-6657', 6324585.000000, 'VYBc3P', 'S', NULL, NULL, NULL, NULL, 899);
INSERT INTO cuenta VALUES ('4767-9095-0546-9814', 5242178.000000, 'Mlv0QuTxX4Pu', 'S', NULL, NULL, NULL, NULL, 508);
INSERT INTO cuenta VALUES ('3985-9819-3116-5865', 797905.000000, 'Qai0M4', 'S', NULL, NULL, NULL, NULL, 751);
INSERT INTO cuenta VALUES ('7847-2436-8417-7320', 7835494.000000, '2oQUsJ0HU', 'S', NULL, NULL, NULL, NULL, 638);
INSERT INTO cuenta VALUES ('5330-5848-7591-3934', 6722278.000000, 'OYF0AdHKK6', 'S', NULL, NULL, NULL, NULL, 488);
INSERT INTO cuenta VALUES ('5572-5438-7645-6397', 5373549.000000, 'ylGah8Mn', 'S', NULL, NULL, NULL, NULL, 218);
INSERT INTO cuenta VALUES ('9333-5118-1529-7984', 849682.000000, 's6YxQE', 'S', NULL, NULL, NULL, NULL, 48);
INSERT INTO cuenta VALUES ('5759-8945-6212-8937', 2840343.000000, '22M99VOJi3G', 'S', NULL, NULL, NULL, NULL, 357);
INSERT INTO cuenta VALUES ('8395-3917-3255-9601', 8607700.000000, '4zwYQt6CtuP', 'S', NULL, NULL, NULL, NULL, 253);
INSERT INTO cuenta VALUES ('4131-2373-0165-9478', 2386603.000000, 'Eyc27ReBCN', 'S', NULL, NULL, NULL, NULL, 899);
INSERT INTO cuenta VALUES ('5033-5983-6056-9695', 9360529.000000, 'G1GyFc', 'S', NULL, NULL, NULL, NULL, 10);
INSERT INTO cuenta VALUES ('0960-7222-9969-6257', 1587270.000000, '3cVKzTWMQmW', 'S', NULL, NULL, NULL, NULL, 729);
INSERT INTO cuenta VALUES ('5486-6285-1590-0991', 5419344.000000, 't9ntDpKK', 'S', NULL, NULL, NULL, NULL, 909);
INSERT INTO cuenta VALUES ('4698-6390-5786-6178', 2226556.000000, 'HJkIfW', 'S', NULL, NULL, NULL, NULL, 383);
INSERT INTO cuenta VALUES ('4342-2780-7568-5225', 6430312.000000, 'liwXN7197wy', 'S', NULL, NULL, NULL, NULL, 260);
INSERT INTO cuenta VALUES ('7518-6779-3429-9920', 4272908.000000, 'Y0RMvVake7', 'S', NULL, NULL, NULL, NULL, 395);
INSERT INTO cuenta VALUES ('3088-3945-1440-3580', 3371289.000000, 'fXu6tFgANFx', 'S', NULL, NULL, NULL, NULL, 934);
INSERT INTO cuenta VALUES ('4408-0595-7155-9372', 9723692.000000, 'I0612P57', 'S', NULL, NULL, NULL, NULL, 350);
INSERT INTO cuenta VALUES ('1033-2607-6812-4756', 5870641.000000, 'KV5PyT2fL4Lc', 'S', NULL, NULL, NULL, NULL, 190);
INSERT INTO cuenta VALUES ('3351-8284-2471-0010', 7080822.000000, 'EFtuxMDNW01', 'S', NULL, NULL, NULL, NULL, 304);
INSERT INTO cuenta VALUES ('0634-8834-4770-5595', 8835911.000000, 'bzeur29rW4P', 'S', NULL, NULL, NULL, NULL, 292);
INSERT INTO cuenta VALUES ('1208-7236-2812-7101', 4489937.000000, 'rNyE0SFnR', 'S', NULL, NULL, NULL, NULL, 517);
INSERT INTO cuenta VALUES ('7122-1814-6549-4560', 2468619.000000, '3jqNF2hAq4Zn', 'S', NULL, NULL, NULL, NULL, 226);
INSERT INTO cuenta VALUES ('6768-3643-4256-4220', 5270691.000000, 'Dluatvk7', 'S', NULL, NULL, NULL, NULL, 303);
INSERT INTO cuenta VALUES ('8591-9284-0584-6791', 3895620.000000, 'oWLkxeraU', 'S', NULL, NULL, NULL, NULL, 750);
INSERT INTO cuenta VALUES ('6777-1760-8793-1361', 4903456.000000, 'CflxuBqyNm', 'S', NULL, NULL, NULL, NULL, 7);
INSERT INTO cuenta VALUES ('3523-3487-9241-1570', 9380916.000000, 'XjL085U8z', 'S', NULL, NULL, NULL, NULL, 493);
INSERT INTO cuenta VALUES ('2917-8025-4648-5433', 1110687.000000, 'pW01tuCJrp55', 'S', NULL, NULL, NULL, NULL, 719);
INSERT INTO cuenta VALUES ('3322-4897-9107-1728', 9492020.000000, 'rbity8g0z', 'S', NULL, NULL, NULL, NULL, 762);
INSERT INTO cuenta VALUES ('1715-3197-2111-3732', 5390294.000000, 'oNjgDR9ImF', 'S', NULL, NULL, NULL, NULL, 42);
INSERT INTO cuenta VALUES ('6097-8025-5355-8835', 2425377.000000, 'XSGQ2ZFoyu', 'S', NULL, NULL, NULL, NULL, 444);
INSERT INTO cuenta VALUES ('0608-5823-5376-5827', 1994106.000000, 'UioIL8F', 'S', NULL, NULL, NULL, NULL, 15);
INSERT INTO cuenta VALUES ('1715-3747-1720-3476', 3182486.000000, 'GXHsIQepug', 'S', NULL, NULL, NULL, NULL, 772);
INSERT INTO cuenta VALUES ('6190-5949-0687-4935', 6727670.000000, 'gmjvTiYfJN', 'S', NULL, NULL, NULL, NULL, 492);
INSERT INTO cuenta VALUES ('9021-7503-0770-8770', 3085615.000000, 'QJVgAq8hpym', 'S', NULL, NULL, NULL, NULL, 720);
INSERT INTO cuenta VALUES ('4290-0070-6740-7625', 7491638.000000, '6EsBRkRqB', 'S', NULL, NULL, NULL, NULL, 876);
INSERT INTO cuenta VALUES ('0666-9829-4314-5827', 6546969.000000, 'IazwSa', 'S', NULL, NULL, NULL, NULL, 854);
INSERT INTO cuenta VALUES ('9627-0264-8010-2775', 1210827.000000, 'U7f1nV1J0', 'S', NULL, NULL, NULL, NULL, 142);
INSERT INTO cuenta VALUES ('9663-7399-2659-9823', 4041187.000000, 'WWOPMaLo', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO cuenta VALUES ('3855-6910-5022-2536', 4769236.000000, 'bPc4uktQa4Dt', 'S', NULL, NULL, NULL, NULL, 104);
INSERT INTO cuenta VALUES ('4279-6890-8395-1948', 8930085.000000, 'kCkc27ON0ayc', 'S', NULL, NULL, NULL, NULL, 111);
INSERT INTO cuenta VALUES ('6435-6102-6448-7735', 4072800.000000, 'i3Bm37RwuH0', 'S', NULL, NULL, NULL, NULL, 965);
INSERT INTO cuenta VALUES ('6311-4328-5738-9003', 1019121.000000, 'r30xKHoPbDlq', 'S', NULL, NULL, NULL, NULL, 595);
INSERT INTO cuenta VALUES ('2848-2744-0190-5423', 9199777.000000, 'FzYWWQ', 'S', NULL, NULL, NULL, NULL, 678);
INSERT INTO cuenta VALUES ('8873-8169-5351-4597', 5819601.000000, '6hZftpr9Ze', 'S', NULL, NULL, NULL, NULL, 525);
INSERT INTO cuenta VALUES ('4043-0854-4270-8728', 3801073.000000, 'crrZF4GpaEv2', 'S', NULL, NULL, NULL, NULL, 603);
INSERT INTO cuenta VALUES ('8474-4826-4105-1942', 2623088.000000, 'EiuMoo0qoB', 'S', NULL, NULL, NULL, NULL, 674);
INSERT INTO cuenta VALUES ('1695-8142-0494-1325', 1585143.000000, 'jlu5SO', 'S', NULL, NULL, NULL, NULL, 144);
INSERT INTO cuenta VALUES ('8949-2140-6063-1411', 9070659.000000, 'BSEVWIfXV', 'S', NULL, NULL, NULL, NULL, 849);
INSERT INTO cuenta VALUES ('4054-9689-4325-5539', 8970609.000000, 'dwFt1NR', 'S', NULL, NULL, NULL, NULL, 99);
INSERT INTO cuenta VALUES ('2555-8595-1981-5035', 7438415.000000, 'hBeuvjynT45h', 'S', NULL, NULL, NULL, NULL, 797);
INSERT INTO cuenta VALUES ('8605-4497-9671-2082', 5474944.000000, '0m1D6lI', 'S', NULL, NULL, NULL, NULL, 500);
INSERT INTO cuenta VALUES ('5244-2130-6489-3790', 2802939.000000, '30Tn0Z15nKkM', 'S', NULL, NULL, NULL, NULL, 969);
INSERT INTO cuenta VALUES ('4928-3149-3924-5463', 6175169.000000, 'aIbi8EnWr2H', 'S', NULL, NULL, NULL, NULL, 624);
INSERT INTO cuenta VALUES ('5005-5947-1669-7433', 3333128.000000, '9q5X4DXP1R', 'S', NULL, NULL, NULL, NULL, 518);
INSERT INTO cuenta VALUES ('3647-6351-8394-2616', 4010668.000000, 'fJMoxkMmlhJy', 'S', NULL, NULL, NULL, NULL, 388);
INSERT INTO cuenta VALUES ('6891-4271-1973-2374', 2648320.000000, 've4aK1GS2', 'S', NULL, NULL, NULL, NULL, 516);
INSERT INTO cuenta VALUES ('9450-2942-2446-0134', 9835593.000000, 'oMKZQOE', 'S', NULL, NULL, NULL, NULL, 845);
INSERT INTO cuenta VALUES ('6492-8933-7311-0833', 1381343.000000, 'NoIKvpR4DXJ5', 'S', NULL, NULL, NULL, NULL, 362);
INSERT INTO cuenta VALUES ('5466-0802-3043-9209', 347902.000000, 'qbBNAdI', 'S', NULL, NULL, NULL, NULL, 398);
INSERT INTO cuenta VALUES ('3000-3455-2371-2202', 2563887.000000, 'kNfUmF35iws', 'S', NULL, NULL, NULL, NULL, 977);
INSERT INTO cuenta VALUES ('6129-3758-3370-1064', 9540304.000000, 'nQAiwPfU4e2', 'S', NULL, NULL, NULL, NULL, 563);
INSERT INTO cuenta VALUES ('4951-5075-6890-1921', 4790551.000000, 'LwsKddt', 'S', NULL, NULL, NULL, NULL, 182);
INSERT INTO cuenta VALUES ('8808-7037-4636-5458', 2723490.000000, '8VGIvk', 'S', NULL, NULL, NULL, NULL, 694);
INSERT INTO cuenta VALUES ('8342-8916-6091-0997', 3956611.000000, 'jZSv5C', 'S', NULL, NULL, NULL, NULL, 713);
INSERT INTO cuenta VALUES ('4102-3571-7578-9316', 807931.000000, 'irNDwWw7S', 'S', NULL, NULL, NULL, NULL, 668);
INSERT INTO cuenta VALUES ('6007-5744-6350-7012', 2768706.000000, 'QqzZQqYog', 'S', NULL, NULL, NULL, NULL, 884);
INSERT INTO cuenta VALUES ('7550-2771-7686-5389', 4233961.000000, '328kqFX59SPD', 'S', NULL, NULL, NULL, NULL, 717);
INSERT INTO cuenta VALUES ('8624-3519-7073-8889', 1862932.000000, 'oLRpMoEu', 'S', NULL, NULL, NULL, NULL, 789);
INSERT INTO cuenta VALUES ('4951-7728-4865-7119', 5618309.000000, '0bQc27yti', 'S', NULL, NULL, NULL, NULL, 860);
INSERT INTO cuenta VALUES ('4210-9603-8763-2613', 7583418.000000, 'ULIZHEv', 'S', NULL, NULL, NULL, NULL, 836);
INSERT INTO cuenta VALUES ('0453-2833-3985-5714', 9980108.000000, 'UW24bK', 'S', NULL, NULL, NULL, NULL, 705);
INSERT INTO cuenta VALUES ('3215-9131-3810-9645', 9699997.000000, 'vXNCazFlc06g', 'S', NULL, NULL, NULL, NULL, 896);
INSERT INTO cuenta VALUES ('9437-9631-0215-9569', 4469667.000000, 'MwS0Hf', 'S', NULL, NULL, NULL, NULL, 514);
INSERT INTO cuenta VALUES ('6111-8936-1243-3669', 1395937.000000, 'mpXNx7N', 'S', NULL, NULL, NULL, NULL, 588);
INSERT INTO cuenta VALUES ('4913-8360-5886-2583', 4652213.000000, 'uNk1Nqkxhtl', 'S', NULL, NULL, NULL, NULL, 799);
INSERT INTO cuenta VALUES ('1630-2763-2918-1826', 7778445.000000, 'ZgBX2n2F5Hiq', 'S', NULL, NULL, NULL, NULL, 22);
INSERT INTO cuenta VALUES ('0467-4180-3844-5016', 636762.000000, '1CBnY6pYPz', 'S', NULL, NULL, NULL, NULL, 877);
INSERT INTO cuenta VALUES ('6711-5787-2026-3049', 5905527.000000, 'v2EM79Dk', 'S', NULL, NULL, NULL, NULL, 713);
INSERT INTO cuenta VALUES ('8016-7570-0156-5732', 1963011.000000, 'JlljvAEo4kW', 'S', NULL, NULL, NULL, NULL, 239);
INSERT INTO cuenta VALUES ('5312-6857-8329-4307', 277634.000000, 'lA1IUbwM', 'S', NULL, NULL, NULL, NULL, 401);
INSERT INTO cuenta VALUES ('8492-1601-9003-0722', 7700141.000000, 'CdkbckF', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO cuenta VALUES ('1850-5689-4698-5360', 5150069.000000, 'Qz0v1cVlyitQ', 'S', NULL, NULL, NULL, NULL, 588);
INSERT INTO cuenta VALUES ('5549-7201-3406-2052', 3750111.000000, '2vgMewvbAo', 'S', NULL, NULL, NULL, NULL, 57);
INSERT INTO cuenta VALUES ('2145-0817-1806-5619', 9259577.000000, '80o2iJQHyJG', 'S', NULL, NULL, NULL, NULL, 267);
INSERT INTO cuenta VALUES ('3386-4862-5982-2134', 3680678.000000, '7r8xEJ7h7Hg', 'S', NULL, NULL, NULL, NULL, 253);
INSERT INTO cuenta VALUES ('8133-2840-6789-4226', 1028591.000000, 'GNaDb8bV', 'S', NULL, NULL, NULL, NULL, 331);
INSERT INTO cuenta VALUES ('4207-6401-0561-6908', 6551123.000000, 'heKPPMFp', 'S', NULL, NULL, NULL, NULL, 306);
INSERT INTO cuenta VALUES ('0918-4472-2848-7283', 6206529.000000, 'Z8KjaSF', 'S', NULL, NULL, NULL, NULL, 847);
INSERT INTO cuenta VALUES ('1747-5102-2907-6287', 5376594.000000, 'H5ptMWsms', 'S', NULL, NULL, NULL, NULL, 844);
INSERT INTO cuenta VALUES ('0409-6333-1242-5641', 9449107.000000, '4jeX4oiTCL3E', 'S', NULL, NULL, NULL, NULL, 262);
INSERT INTO cuenta VALUES ('2301-0035-4173-7602', 2853939.000000, 'vL0mxWtw', 'S', NULL, NULL, NULL, NULL, 334);
INSERT INTO cuenta VALUES ('0972-2060-7570-4742', 4538273.000000, 'oanAltLLrLQs', 'S', NULL, NULL, NULL, NULL, 417);
INSERT INTO cuenta VALUES ('8400-7278-4743-0412', 5859517.000000, 'rcHKWrf', 'S', NULL, NULL, NULL, NULL, 822);
INSERT INTO cuenta VALUES ('1630-0325-3078-1771', 1959336.000000, 'pD54tAd5', 'S', NULL, NULL, NULL, NULL, 338);
INSERT INTO cuenta VALUES ('9762-0319-9292-3843', 1495355.000000, 'GIDAZuoDdB', 'S', NULL, NULL, NULL, NULL, 775);
INSERT INTO cuenta VALUES ('3055-9395-0551-1743', 4506963.000000, 'RAbeogqk', 'S', NULL, NULL, NULL, NULL, 97);
INSERT INTO cuenta VALUES ('3690-3934-5226-0835', 8699047.000000, 'ljkTn12', 'S', NULL, NULL, NULL, NULL, 470);
INSERT INTO cuenta VALUES ('6618-0714-7209-2612', 2447886.000000, 'jHjHuhHv', 'S', NULL, NULL, NULL, NULL, 906);
INSERT INTO cuenta VALUES ('8312-8004-6508-8521', 9086313.000000, 'ynho9Yj', 'S', NULL, NULL, NULL, NULL, 432);
INSERT INTO cuenta VALUES ('6475-6514-2453-4835', 9777557.000000, '1dUBlWt', 'S', NULL, NULL, NULL, NULL, 623);
INSERT INTO cuenta VALUES ('8378-6768-8364-3911', 7897872.000000, 'Hv1GzF', 'S', NULL, NULL, NULL, NULL, 947);
INSERT INTO cuenta VALUES ('4005-4766-2723-3197', 6135760.000000, 'EC3HpvA', 'S', NULL, NULL, NULL, NULL, 344);
INSERT INTO cuenta VALUES ('0687-8276-6997-1825', 377161.000000, 'eXa2Lp', 'S', NULL, NULL, NULL, NULL, 337);
INSERT INTO cuenta VALUES ('7990-8986-5243-0174', 1850154.000000, '4892htsI', 'S', NULL, NULL, NULL, NULL, 308);
INSERT INTO cuenta VALUES ('6362-1048-2724-2482', 8731462.000000, 'IiiFMuV', 'S', NULL, NULL, NULL, NULL, 660);
INSERT INTO cuenta VALUES ('1103-8690-6162-9912', 1972965.000000, 'HWJlwaJkWbKv', 'S', NULL, NULL, NULL, NULL, 519);
INSERT INTO cuenta VALUES ('9312-3571-8136-5150', 8799370.000000, 'rByYdvFc8', 'S', NULL, NULL, NULL, NULL, 357);
INSERT INTO cuenta VALUES ('2541-3883-4415-5470', 5818239.000000, '7lbOhc', 'S', NULL, NULL, NULL, NULL, 275);
INSERT INTO cuenta VALUES ('1155-5855-4355-6453', 2383310.000000, 'JpqIK36', 'S', NULL, NULL, NULL, NULL, 240);
INSERT INTO cuenta VALUES ('0481-3816-5327-8449', 1195292.000000, 'FXjrdy', 'S', NULL, NULL, NULL, NULL, 906);
INSERT INTO cuenta VALUES ('7768-6079-3106-5111', 7109282.000000, 'l6uhjGRRVq', 'S', NULL, NULL, NULL, NULL, 508);
INSERT INTO cuenta VALUES ('9976-0588-1601-7673', 8784615.000000, 'f2Fz9SFFIObE', 'S', NULL, NULL, NULL, NULL, 507);
INSERT INTO cuenta VALUES ('9463-7248-4089-1277', 6691132.000000, 'QVdPI3II', 'S', NULL, NULL, NULL, NULL, 131);
INSERT INTO cuenta VALUES ('5537-9720-1139-0893', 7600753.000000, '74QkR1r', 'S', NULL, NULL, NULL, NULL, 111);
INSERT INTO cuenta VALUES ('4478-6872-9766-2388', 6917592.000000, 'PCNHpA9XP', 'S', NULL, NULL, NULL, NULL, 827);
INSERT INTO cuenta VALUES ('5737-9930-3751-6329', 2881809.000000, 'JGQuhuzVfYfz', 'S', NULL, NULL, NULL, NULL, 484);
INSERT INTO cuenta VALUES ('4465-3058-5886-7856', 4275649.000000, '8Mosqxb', 'S', NULL, NULL, NULL, NULL, 80);
INSERT INTO cuenta VALUES ('8745-2834-9122-8299', 3721950.000000, 'EPeVjDuPwCR', 'S', NULL, NULL, NULL, NULL, 330);
INSERT INTO cuenta VALUES ('3562-0267-9135-6995', 2353805.000000, 'xLaACdFO', 'S', NULL, NULL, NULL, NULL, 158);
INSERT INTO cuenta VALUES ('5830-2732-8025-4631', 5150720.000000, '4DTqOz7Jc', 'S', NULL, NULL, NULL, NULL, 959);
INSERT INTO cuenta VALUES ('7306-9992-1336-8948', 2773138.000000, 'Umrt3k', 'S', NULL, NULL, NULL, NULL, 984);
INSERT INTO cuenta VALUES ('1082-9900-0565-9255', 2662129.000000, 'BPUz9u4', 'S', NULL, NULL, NULL, NULL, 642);
INSERT INTO cuenta VALUES ('8466-9796-9588-7753', 7593321.000000, 'Y5D2zsez80H', 'S', NULL, NULL, NULL, NULL, 488);
INSERT INTO cuenta VALUES ('0356-9831-7390-6579', 8596573.000000, 'O5cQCsHRn9', 'S', NULL, NULL, NULL, NULL, 417);
INSERT INTO cuenta VALUES ('8468-1656-5592-5265', 6185989.000000, 'pNkIiv6', 'S', NULL, NULL, NULL, NULL, 143);
INSERT INTO cuenta VALUES ('9213-9472-8334-0889', 8296532.000000, '7aKSe8B', 'S', NULL, NULL, NULL, NULL, 433);
INSERT INTO cuenta VALUES ('8721-1513-2509-7767', 8499347.000000, 'GEwUTbXylG', 'S', NULL, NULL, NULL, NULL, 699);
INSERT INTO cuenta VALUES ('3546-4779-2181-9597', 7700693.000000, '3fTAlZXCz2q', 'S', NULL, NULL, NULL, NULL, 704);
INSERT INTO cuenta VALUES ('4568-2630-8285-9226', 4394469.000000, '9ICTfg2jKiF', 'S', NULL, NULL, NULL, NULL, 676);
INSERT INTO cuenta VALUES ('8682-7001-7740-8714', 5524519.000000, 'yXUSeuLOHfo', 'S', NULL, NULL, NULL, NULL, 185);
INSERT INTO cuenta VALUES ('0403-3112-9590-3201', 8926876.000000, 'gvWDH5xu', 'S', NULL, NULL, NULL, NULL, 464);
INSERT INTO cuenta VALUES ('2018-6394-5751-8840', 2689703.000000, 'p34yMvDKFc6P', 'S', NULL, NULL, NULL, NULL, 686);
INSERT INTO cuenta VALUES ('7572-5956-2301-9837', 2171101.000000, 'CbZtEehHn', 'S', NULL, NULL, NULL, NULL, 990);
INSERT INTO cuenta VALUES ('2138-4325-5167-1782', 2764755.000000, 's11jPv', 'S', NULL, NULL, NULL, NULL, 478);
INSERT INTO cuenta VALUES ('5844-8348-1804-8665', 7301852.000000, 'Qo456UUl', 'S', NULL, NULL, NULL, NULL, 644);
INSERT INTO cuenta VALUES ('3669-9279-5673-6803', 9104454.000000, '6VmCwr', 'S', NULL, NULL, NULL, NULL, 813);
INSERT INTO cuenta VALUES ('6064-9269-3413-4398', 1971564.000000, '2Rzrp6afx', 'S', NULL, NULL, NULL, NULL, 312);
INSERT INTO cuenta VALUES ('0825-9778-0336-3395', 8657002.000000, 'uwQC751evZg', 'S', NULL, NULL, NULL, NULL, 92);
INSERT INTO cuenta VALUES ('9161-9522-4235-5014', 1759350.000000, 'i5ch3Z', 'S', NULL, NULL, NULL, NULL, 625);
INSERT INTO cuenta VALUES ('0891-0231-2331-8503', 4744379.000000, 'amhDQUE', 'S', NULL, NULL, NULL, NULL, 505);
INSERT INTO cuenta VALUES ('1442-1680-8095-3937', 6671538.000000, 'QH3IJzD', 'S', NULL, NULL, NULL, NULL, 531);
INSERT INTO cuenta VALUES ('9925-3107-5750-2633', 2528563.000000, '0ALwLLkHTWt', 'S', NULL, NULL, NULL, NULL, 606);
INSERT INTO cuenta VALUES ('1378-4633-9883-7318', 8806460.000000, '5vLOuvKsgvsb', 'S', NULL, NULL, NULL, NULL, 719);
INSERT INTO cuenta VALUES ('5077-1247-7889-2007', 9448996.000000, 'L9TdOSfEjM', 'S', NULL, NULL, NULL, NULL, 694);
INSERT INTO cuenta VALUES ('6048-1014-0728-9800', 683881.000000, 'gVGUPNgpixH', 'S', NULL, NULL, NULL, NULL, 435);
INSERT INTO cuenta VALUES ('6808-5264-7535-7275', 7799211.000000, 'QFA6Bx37', 'S', NULL, NULL, NULL, NULL, 907);
INSERT INTO cuenta VALUES ('4794-0105-5731-4107', 5470069.000000, 're132x5kxE', 'S', NULL, NULL, NULL, NULL, 727);
INSERT INTO cuenta VALUES ('6613-3631-2238-5489', 789198.000000, 'UxyuduxUL', 'S', NULL, NULL, NULL, NULL, 30);
INSERT INTO cuenta VALUES ('4891-4957-9489-6325', 1246789.000000, 'Tg9Jt9I', 'S', NULL, NULL, NULL, NULL, 667);
INSERT INTO cuenta VALUES ('9499-0484-0105-2325', 9331102.000000, 'BdBx93qIQC', 'S', NULL, NULL, NULL, NULL, 229);
INSERT INTO cuenta VALUES ('5579-2666-5576-4586', 1598604.000000, 'QzqVszxASIG', 'S', NULL, NULL, NULL, NULL, 563);
INSERT INTO cuenta VALUES ('7194-4677-4423-8154', 8573521.000000, '7qgajHpuSi', 'S', NULL, NULL, NULL, NULL, 878);
INSERT INTO cuenta VALUES ('1146-6330-1962-9289', 5211570.000000, 'qCC9io', 'S', NULL, NULL, NULL, NULL, 128);
INSERT INTO cuenta VALUES ('4673-9900-9578-2396', 8805878.000000, 'iYoTWyk', 'S', NULL, NULL, NULL, NULL, 544);
INSERT INTO cuenta VALUES ('3852-7730-6879-2858', 4970164.000000, 'YY4Nlyp6i', 'S', NULL, NULL, NULL, NULL, 379);
INSERT INTO cuenta VALUES ('3640-0117-7066-8935', 991527.000000, 'g5LlB7ghJnzd', 'S', NULL, NULL, NULL, NULL, 793);
INSERT INTO cuenta VALUES ('8748-5372-2360-0811', 8986736.000000, 'dKhXVG9oYuwI', 'S', NULL, NULL, NULL, NULL, 113);
INSERT INTO cuenta VALUES ('3006-7303-2560-7784', 4015977.000000, 'B0anfVfrsPt', 'S', NULL, NULL, NULL, NULL, 67);
INSERT INTO cuenta VALUES ('2629-3742-2158-2159', 6710396.000000, 'Ps0jiUO', 'S', NULL, NULL, NULL, NULL, 676);
INSERT INTO cuenta VALUES ('2665-2277-4245-1300', 452904.000000, 'mtDVtlAhi9TU', 'S', NULL, NULL, NULL, NULL, 92);
INSERT INTO cuenta VALUES ('0313-5305-1092-1252', 1871801.000000, 'ndAERZIjZcuK', 'S', NULL, NULL, NULL, NULL, 113);
INSERT INTO cuenta VALUES ('8987-3325-9027-4239', 8378816.000000, 'nCn0FrZaD2v', 'S', NULL, NULL, NULL, NULL, 571);
INSERT INTO cuenta VALUES ('7564-4349-1742-3096', 5364088.000000, 'VXWi00', 'S', NULL, NULL, NULL, NULL, 797);
INSERT INTO cuenta VALUES ('7987-5653-0291-8127', 3401931.000000, 'wZuHP16', 'S', NULL, NULL, NULL, NULL, 107);
INSERT INTO cuenta VALUES ('1826-7287-3139-9869', 9618791.000000, 'CWXQd4', 'S', NULL, NULL, NULL, NULL, 79);
INSERT INTO cuenta VALUES ('1162-6176-3734-0538', 8728435.000000, 'jZqcvZ', 'S', NULL, NULL, NULL, NULL, 368);
INSERT INTO cuenta VALUES ('3807-6631-3515-0049', 7689777.000000, 'uStaw9a', 'S', NULL, NULL, NULL, NULL, 773);
INSERT INTO cuenta VALUES ('1534-4875-2315-1642', 6026934.000000, 'AIXojedAH6', 'S', NULL, NULL, NULL, NULL, 120);
INSERT INTO cuenta VALUES ('5785-4986-8978-3812', 8695136.000000, 'l7dWVsduthd6', 'S', NULL, NULL, NULL, NULL, 22);
INSERT INTO cuenta VALUES ('6304-3240-5715-4443', 7248402.000000, 'RPXebdb3WS', 'S', NULL, NULL, NULL, NULL, 132);
INSERT INTO cuenta VALUES ('5979-9253-9657-1457', 8085271.000000, 'b6ZUTo', 'S', NULL, NULL, NULL, NULL, 996);
INSERT INTO cuenta VALUES ('5266-0124-3804-8460', 2418550.000000, 'QRHUaVx', 'S', NULL, NULL, NULL, NULL, 716);
INSERT INTO cuenta VALUES ('8577-0115-6109-0119', 1104942.000000, 'CmtiRlyYN0v', 'S', NULL, NULL, NULL, NULL, 620);
INSERT INTO cuenta VALUES ('9712-2379-8781-1871', 5025725.000000, 'T8VNMwHwVOE', 'S', NULL, NULL, NULL, NULL, 713);
INSERT INTO cuenta VALUES ('5873-3834-6546-3391', 3712989.000000, 'aQ3upy5rgkzB', 'S', NULL, NULL, NULL, NULL, 544);
INSERT INTO cuenta VALUES ('3387-1986-5729-8240', 6040646.000000, 'LD22ajp4P', 'S', NULL, NULL, NULL, NULL, 773);
INSERT INTO cuenta VALUES ('5229-6840-4157-7095', 9426856.000000, '8wHWR15Qb', 'S', NULL, NULL, NULL, NULL, 351);
INSERT INTO cuenta VALUES ('2876-9921-1464-1842', 2078837.000000, 'wGGWaybp', 'S', NULL, NULL, NULL, NULL, 717);
INSERT INTO cuenta VALUES ('5184-3234-0954-6716', 268883.000000, 'XoMb6NiOt7', 'S', NULL, NULL, NULL, NULL, 639);
INSERT INTO cuenta VALUES ('6398-5834-0162-1113', 3357472.000000, 'qZqHa3Un9lZ', 'S', NULL, NULL, NULL, NULL, 239);
INSERT INTO cuenta VALUES ('0680-3867-7255-5254', 3357314.000000, 'qsfOdx', 'S', NULL, NULL, NULL, NULL, 833);
INSERT INTO cuenta VALUES ('0378-0104-3042-6942', 1204972.000000, 'T7tN3XelMsA', 'S', NULL, NULL, NULL, NULL, 401);
INSERT INTO cuenta VALUES ('6473-3225-8322-1257', 928950.000000, '18r0aPH', 'S', NULL, NULL, NULL, NULL, 509);
INSERT INTO cuenta VALUES ('3354-2503-9453-3396', 261267.000000, 'Pv6eGB', 'S', NULL, NULL, NULL, NULL, 444);
INSERT INTO cuenta VALUES ('3554-6362-8104-8561', 9659847.000000, '6jUO2j7ki', 'S', NULL, NULL, NULL, NULL, 968);
INSERT INTO cuenta VALUES ('1758-5506-7922-1120', 499709.000000, 'tDHkjSI', 'S', NULL, NULL, NULL, NULL, 8);
INSERT INTO cuenta VALUES ('0000-6776-1365-3228', 635094.000000, 'hmKnRrGG', 'S', NULL, NULL, NULL, NULL, 572);
INSERT INTO cuenta VALUES ('3855-0597-8284-5530', 6473206.000000, 'lNStbhShbOwx', 'S', NULL, NULL, NULL, NULL, 171);
INSERT INTO cuenta VALUES ('7397-0092-6771-9152', 1065374.000000, 'mmM5il8vcL', 'S', NULL, NULL, NULL, NULL, 851);
INSERT INTO cuenta VALUES ('2395-0928-0703-2567', 6160552.000000, 'TBZKgtXng', 'S', NULL, NULL, NULL, NULL, 218);
INSERT INTO cuenta VALUES ('2390-2819-1532-8067', 4260125.000000, 'w3xnI1', 'S', NULL, NULL, NULL, NULL, 802);
INSERT INTO cuenta VALUES ('6274-9710-2259-3061', 4951496.000000, 'UIta0YinaXY', 'S', NULL, NULL, NULL, NULL, 889);
INSERT INTO cuenta VALUES ('4517-0374-2606-4164', 5592305.000000, 'dMdbtX', 'S', NULL, NULL, NULL, NULL, 67);
INSERT INTO cuenta VALUES ('2156-8000-0510-5937', 7812089.000000, 'EXgyinXE679', 'S', NULL, NULL, NULL, NULL, 536);
INSERT INTO cuenta VALUES ('4349-8338-3806-3287', 858249.000000, 'y262XTwQqHD', 'S', NULL, NULL, NULL, NULL, 543);
INSERT INTO cuenta VALUES ('3255-4842-6801-8067', 7684959.000000, '11ICI0EhOjPN', 'S', NULL, NULL, NULL, NULL, 495);
INSERT INTO cuenta VALUES ('9546-3916-0230-6656', 3797335.000000, 'sg4OSZAs5TS6', 'S', NULL, NULL, NULL, NULL, 843);
INSERT INTO cuenta VALUES ('6436-9512-6125-5181', 9902473.000000, 'SparETZx9', 'S', NULL, NULL, NULL, NULL, 865);
INSERT INTO cuenta VALUES ('9747-1517-2395-2492', 2268949.000000, 'Dzudz2', 'S', NULL, NULL, NULL, NULL, 902);
INSERT INTO cuenta VALUES ('0227-0721-7198-1351', 7601967.000000, '81jQPLtx', 'S', NULL, NULL, NULL, NULL, 32);
INSERT INTO cuenta VALUES ('0045-0476-8403-9704', 8356600.000000, '53pBu7RkP7', 'S', NULL, NULL, NULL, NULL, 779);
INSERT INTO cuenta VALUES ('8982-9502-1316-3608', 4158607.000000, 'KI6lbOgEpQy', 'S', NULL, NULL, NULL, NULL, 985);
INSERT INTO cuenta VALUES ('4506-9946-0648-3078', 1574993.000000, 'Dv2l0whR6', 'S', NULL, NULL, NULL, NULL, 332);
INSERT INTO cuenta VALUES ('1718-1600-6221-7651', 834641.000000, 'lA0nUtq', 'S', NULL, NULL, NULL, NULL, 882);
INSERT INTO cuenta VALUES ('3301-3145-4563-3461', 8307223.000000, 'obsaZaNp', 'S', NULL, NULL, NULL, NULL, 545);
INSERT INTO cuenta VALUES ('1981-2371-1371-2192', 5482210.000000, 'YksC5yBK41J', 'S', NULL, NULL, NULL, NULL, 849);
INSERT INTO cuenta VALUES ('7336-5441-4034-2393', 7253474.000000, 'T1TTwVfKMHvI', 'S', NULL, NULL, NULL, NULL, 147);
INSERT INTO cuenta VALUES ('7470-2200-3182-4616', 1967049.000000, 'qBszJzKB8', 'S', NULL, NULL, NULL, NULL, 706);
INSERT INTO cuenta VALUES ('2272-9480-0396-2342', 8565282.000000, 'izoKMSJ4wPIN', 'S', NULL, NULL, NULL, NULL, 485);
INSERT INTO cuenta VALUES ('8024-1931-9925-3246', 9486657.000000, 'ZamBAQoLsv', 'S', NULL, NULL, NULL, NULL, 239);
INSERT INTO cuenta VALUES ('3067-4204-6255-8565', 1986413.000000, '60fdbfZ1yIq', 'S', NULL, NULL, NULL, NULL, 694);
INSERT INTO cuenta VALUES ('6749-3153-3951-2347', 1821009.000000, 'NelvI7HO4', 'S', NULL, NULL, NULL, NULL, 563);
INSERT INTO cuenta VALUES ('5625-1224-5271-5271', 2635821.000000, 'is8eDr', 'S', NULL, NULL, NULL, NULL, 674);
INSERT INTO cuenta VALUES ('8407-1393-3494-0961', 2294939.000000, 'CNWV2RETw', 'S', NULL, NULL, NULL, NULL, 181);
INSERT INTO cuenta VALUES ('4624-9856-7771-2136', 2266215.000000, 'fgv569nl', 'S', NULL, NULL, NULL, NULL, 886);
INSERT INTO cuenta VALUES ('3687-8768-0600-9167', 7655368.000000, 'LzwaqC', 'S', NULL, NULL, NULL, NULL, 260);
INSERT INTO cuenta VALUES ('0284-5822-9985-1823', 1808535.000000, 'U3JI4Rj6GA7', 'S', NULL, NULL, NULL, NULL, 458);
INSERT INTO cuenta VALUES ('1196-4351-6977-6586', 4016962.000000, 'DPGthJ2P', 'S', NULL, NULL, NULL, NULL, 298);
INSERT INTO cuenta VALUES ('3549-8964-9198-7811', 4633040.000000, 'ykbh8CLozU', 'S', NULL, NULL, NULL, NULL, 770);
INSERT INTO cuenta VALUES ('5955-2231-1011-3319', 1249987.000000, 'vn3MkdL9Wn', 'S', NULL, NULL, NULL, NULL, 804);
INSERT INTO cuenta VALUES ('5568-5031-0968-7861', 3819033.000000, 'ijfS7IkzZtJ', 'S', NULL, NULL, NULL, NULL, 234);
INSERT INTO cuenta VALUES ('1908-2065-1267-5798', 6136490.000000, '0vRybt4', 'S', NULL, NULL, NULL, NULL, 70);
INSERT INTO cuenta VALUES ('2747-7142-0939-8329', 9960307.000000, '7ESolU9kR', 'S', NULL, NULL, NULL, NULL, 886);
INSERT INTO cuenta VALUES ('9933-5970-3699-6091', 5333562.000000, 'jQotGPxm1', 'S', NULL, NULL, NULL, NULL, 855);
INSERT INTO cuenta VALUES ('4708-1401-7309-7732', 6968639.000000, 'M99ArN', 'S', NULL, NULL, NULL, NULL, 341);
INSERT INTO cuenta VALUES ('6136-4983-1515-1358', 4530528.000000, 'tSzIIwFQq', 'S', NULL, NULL, NULL, NULL, 889);
INSERT INTO cuenta VALUES ('3667-4260-2531-5457', 365497.000000, 'PzMpY8Ctoyr', 'S', NULL, NULL, NULL, NULL, 508);
INSERT INTO cuenta VALUES ('7602-2234-9590-9298', 7322598.000000, 's82Eu2mIC', 'S', NULL, NULL, NULL, NULL, 611);
INSERT INTO cuenta VALUES ('3108-4330-2344-2744', 6558436.000000, 'K5qYAG', 'S', NULL, NULL, NULL, NULL, 45);
INSERT INTO cuenta VALUES ('6785-2621-2751-0787', 3702692.000000, '8mLl6Xq2', 'S', NULL, NULL, NULL, NULL, 650);
INSERT INTO cuenta VALUES ('4840-6660-6885-1134', 3606492.000000, 'BWHlqRq', 'S', NULL, NULL, NULL, NULL, 532);
INSERT INTO cuenta VALUES ('6564-1153-9107-9567', 4143340.000000, '2OMJu2yq', 'S', NULL, NULL, NULL, NULL, 502);
INSERT INTO cuenta VALUES ('7640-1695-5833-4669', 9959176.000000, 'HHAw3v', 'S', NULL, NULL, NULL, NULL, 446);
INSERT INTO cuenta VALUES ('9910-6771-0580-1164', 6029670.000000, 'U0y2lj7mpr', 'S', NULL, NULL, NULL, NULL, 580);
INSERT INTO cuenta VALUES ('9853-9209-7829-2433', 7950116.000000, 'jJKsl95BF', 'S', NULL, NULL, NULL, NULL, 193);
INSERT INTO cuenta VALUES ('0606-3429-5571-0260', 8127000.000000, 'ZBZdn6', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO cuenta VALUES ('4260-3288-0566-9828', 2602696.000000, 'D87yyc8', 'S', NULL, NULL, NULL, NULL, 997);
INSERT INTO cuenta VALUES ('1532-6208-2667-3577', 5340127.000000, 'YFhgXreD1iqv', 'S', NULL, NULL, NULL, NULL, 151);
INSERT INTO cuenta VALUES ('4183-0452-3692-1286', 7145558.000000, 'gbqgWKXf', 'S', NULL, NULL, NULL, NULL, 964);
INSERT INTO cuenta VALUES ('5672-3801-1615-6909', 1908058.000000, 'qXHBDVsvE6', 'S', NULL, NULL, NULL, NULL, 689);
INSERT INTO cuenta VALUES ('7621-5302-1629-5018', 919551.000000, '3i0xuXnw', 'S', NULL, NULL, NULL, NULL, 219);
INSERT INTO cuenta VALUES ('7659-3027-0066-1339', 7946336.000000, 'PK06ykD', 'S', NULL, NULL, NULL, NULL, 69);
INSERT INTO cuenta VALUES ('2910-1844-0437-6769', 8978625.000000, 'eekOS4WMFDWk', 'S', NULL, NULL, NULL, NULL, 861);
INSERT INTO cuenta VALUES ('8485-7736-1527-7654', 6807570.000000, 'jOBHUslUvZO', 'S', NULL, NULL, NULL, NULL, 734);
INSERT INTO cuenta VALUES ('8175-4503-1216-4465', 1485449.000000, 'IImEYdHgl', 'S', NULL, NULL, NULL, NULL, 764);
INSERT INTO cuenta VALUES ('8530-4521-4087-5531', 1263087.000000, 'Qq2BaxIRDZD', 'S', NULL, NULL, NULL, NULL, 600);
INSERT INTO cuenta VALUES ('1960-7918-1993-3552', 7238416.000000, '8HvCk5tN', 'S', NULL, NULL, NULL, NULL, 645);
INSERT INTO cuenta VALUES ('9193-7995-2387-3729', 8591570.000000, '0MVXaRo1nb', 'S', NULL, NULL, NULL, NULL, 721);
INSERT INTO cuenta VALUES ('5457-3178-2588-0515', 5096188.000000, 'D2ZW3ftlAY', 'S', NULL, NULL, NULL, NULL, 968);
INSERT INTO cuenta VALUES ('6349-5180-9604-7878', 4610262.000000, 'EHQsgADyYV', 'S', NULL, NULL, NULL, NULL, 908);
INSERT INTO cuenta VALUES ('1347-8873-3984-4550', 6389332.000000, 'IkwiRYhRIo', 'S', NULL, NULL, NULL, NULL, 969);
INSERT INTO cuenta VALUES ('0549-2382-3910-1620', 885570.000000, 'B55FO5I', 'S', NULL, NULL, NULL, NULL, 656);
INSERT INTO cuenta VALUES ('3479-3177-0505-1398', 9023496.000000, 'QlU1Wt7b', 'S', NULL, NULL, NULL, NULL, 214);
INSERT INTO cuenta VALUES ('1053-5269-1233-3686', 9321228.000000, 'EL1m7rap7b', 'S', NULL, NULL, NULL, NULL, 466);
INSERT INTO cuenta VALUES ('4517-3882-5627-6267', 5178864.000000, 'iLwWUIuw', 'S', NULL, NULL, NULL, NULL, 204);
INSERT INTO cuenta VALUES ('1578-1048-0934-8687', 2064701.000000, 'pwSFkzULGQJK', 'S', NULL, NULL, NULL, NULL, 810);
INSERT INTO cuenta VALUES ('3387-7546-0191-5907', 932194.000000, '4XmCUXWxl', 'S', NULL, NULL, NULL, NULL, 89);
INSERT INTO cuenta VALUES ('1601-3982-6627-3093', 7552162.000000, 'kopRL7C3', 'S', NULL, NULL, NULL, NULL, 956);
INSERT INTO cuenta VALUES ('1093-0634-7205-3552', 2040607.000000, 'TgNxI2DeklY', 'S', NULL, NULL, NULL, NULL, 794);
INSERT INTO cuenta VALUES ('8287-0334-0691-6182', 4916019.000000, 'YCgsS1A', 'S', NULL, NULL, NULL, NULL, 179);
INSERT INTO cuenta VALUES ('8339-2241-3348-0775', 5266742.000000, 'aS1aVMk4dNhA', 'S', NULL, NULL, NULL, NULL, 97);
INSERT INTO cuenta VALUES ('2314-7715-6174-9999', 5275066.000000, 'AFQOAGv', 'S', NULL, NULL, NULL, NULL, 650);
INSERT INTO cuenta VALUES ('9103-3272-0052-0319', 8300345.000000, 'sukn85hj4a3V', 'S', NULL, NULL, NULL, NULL, 420);
INSERT INTO cuenta VALUES ('5419-3945-6775-8493', 6157897.000000, 'aCtGrUbn0', 'S', NULL, NULL, NULL, NULL, 110);
INSERT INTO cuenta VALUES ('2063-5146-8198-0593', 9239498.000000, 'Zoe5I8Msn', 'S', NULL, NULL, NULL, NULL, 567);
INSERT INTO cuenta VALUES ('8619-2518-6666-0864', 2192900.000000, 'Pm5Khu9p', 'S', NULL, NULL, NULL, NULL, 287);
INSERT INTO cuenta VALUES ('5833-2684-4120-0865', 5535627.000000, 'G1j5uT', 'S', NULL, NULL, NULL, NULL, 132);
INSERT INTO cuenta VALUES ('5524-2067-3812-5571', 8511181.000000, 'qfzXhlY3gzV', 'S', NULL, NULL, NULL, NULL, 116);
INSERT INTO cuenta VALUES ('1095-5063-7641-5690', 6764228.000000, '0IaZygp', 'S', NULL, NULL, NULL, NULL, 72);
INSERT INTO cuenta VALUES ('0159-5568-6123-7859', 4965020.000000, 'axG6Kkvaxg', 'S', NULL, NULL, NULL, NULL, 482);
INSERT INTO cuenta VALUES ('5324-3024-2677-0976', 3933480.000000, 'pTdlXnylUw', 'S', NULL, NULL, NULL, NULL, 122);
INSERT INTO cuenta VALUES ('4672-4448-6958-1651', 4649867.000000, 'E8mz6UaYGy', 'S', NULL, NULL, NULL, NULL, 579);
INSERT INTO cuenta VALUES ('2714-0030-7289-7648', 9566364.000000, 'HtYKfi8GTu', 'S', NULL, NULL, NULL, NULL, 607);
INSERT INTO cuenta VALUES ('1606-2637-6201-0754', 7826469.000000, 'IO2pdtBKL', 'S', NULL, NULL, NULL, NULL, 695);
INSERT INTO cuenta VALUES ('7291-0668-5133-0765', 6435261.000000, 'xMRC2P', 'S', NULL, NULL, NULL, NULL, 673);
INSERT INTO cuenta VALUES ('6411-4058-3236-2281', 8358161.000000, 'y7K4LTUfNBk8', 'S', NULL, NULL, NULL, NULL, 665);
INSERT INTO cuenta VALUES ('2493-2031-4817-5437', 6099454.000000, 'RgntlvIH2M', 'S', NULL, NULL, NULL, NULL, 905);
INSERT INTO cuenta VALUES ('7586-8836-4235-2095', 9676337.000000, 'ou6o8W', 'S', NULL, NULL, NULL, NULL, 803);
INSERT INTO cuenta VALUES ('6107-4040-7932-2543', 2660871.000000, 'SBcN6u', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO cuenta VALUES ('3002-2641-4870-1125', 8896465.000000, '3wqFhitL7XK', 'S', NULL, NULL, NULL, NULL, 304);
INSERT INTO cuenta VALUES ('1249-3374-4103-2331', 3414123.000000, 'y5RqeVjzj', 'S', NULL, NULL, NULL, NULL, 374);
INSERT INTO cuenta VALUES ('1198-5122-1988-0870', 9544529.000000, 'WECPkXnVDl1i', 'S', NULL, NULL, NULL, NULL, 823);
INSERT INTO cuenta VALUES ('9819-7217-3274-2596', 9685227.000000, 'TnLO6MqDlfsR', 'S', NULL, NULL, NULL, NULL, 530);
INSERT INTO cuenta VALUES ('3253-7328-6999-0962', 4132583.000000, '0hTieqRL', 'S', NULL, NULL, NULL, NULL, 854);
INSERT INTO cuenta VALUES ('4612-1514-5393-4220', 4037090.000000, 'KoBKQ1PZ', 'S', NULL, NULL, NULL, NULL, 609);
INSERT INTO cuenta VALUES ('1738-9671-9194-8889', 8277165.000000, 'UJ74QQ', 'S', NULL, NULL, NULL, NULL, 177);
INSERT INTO cuenta VALUES ('7709-4313-9877-9923', 3630731.000000, 'sUJc4C6MzctK', 'S', NULL, NULL, NULL, NULL, 878);
INSERT INTO cuenta VALUES ('3277-5656-9245-8627', 5470237.000000, 'JhmpzvyDhG1H', 'S', NULL, NULL, NULL, NULL, 69);
INSERT INTO cuenta VALUES ('0828-1743-5983-0837', 8142426.000000, 'PC8zxC6', 'S', NULL, NULL, NULL, NULL, 966);
INSERT INTO cuenta VALUES ('1689-6709-7784-0276', 9284721.000000, 'bdXBEDVvn', 'S', NULL, NULL, NULL, NULL, 976);
INSERT INTO cuenta VALUES ('5831-3636-3422-4753', 4670931.000000, 'tianImsjITKR', 'S', NULL, NULL, NULL, NULL, 635);
INSERT INTO cuenta VALUES ('6145-9881-9639-0934', 1956626.000000, 'uXqX7CFQppl', 'S', NULL, NULL, NULL, NULL, 669);
INSERT INTO cuenta VALUES ('0075-4915-0537-9440', 5002592.000000, 'iF4WYyxqMa', 'S', NULL, NULL, NULL, NULL, 776);
INSERT INTO cuenta VALUES ('2702-8403-9856-5066', 7389418.000000, 'KwmRnnNU4r4', 'S', NULL, NULL, NULL, NULL, 433);
INSERT INTO cuenta VALUES ('4217-1088-5114-3642', 8567691.000000, 'by6JrACXHwI', 'S', NULL, NULL, NULL, NULL, 426);
INSERT INTO cuenta VALUES ('4559-9401-2235-5375', 9477073.000000, 'RzTs3cNl', 'S', NULL, NULL, NULL, NULL, 155);
INSERT INTO cuenta VALUES ('6348-1833-6423-1813', 508064.000000, 'ONfuh4Vrpn', 'S', NULL, NULL, NULL, NULL, 858);
INSERT INTO cuenta VALUES ('5727-6848-4739-0010', 1577092.000000, '92N4M4gp3Y', 'S', NULL, NULL, NULL, NULL, 263);
INSERT INTO cuenta VALUES ('0547-6034-7717-0790', 6511877.000000, 'JbgF6Du9', 'S', NULL, NULL, NULL, NULL, 424);
INSERT INTO cuenta VALUES ('5948-7343-7154-5778', 9555723.000000, 'h2mXTNF0', 'S', NULL, NULL, NULL, NULL, 763);
INSERT INTO cuenta VALUES ('9467-8293-7332-0515', 5509368.000000, 'QXwJPcWyRA', 'S', NULL, NULL, NULL, NULL, 843);
INSERT INTO cuenta VALUES ('8798-8814-6536-9077', 4793996.000000, 'vO9PACtvV', 'S', NULL, NULL, NULL, NULL, 405);
INSERT INTO cuenta VALUES ('0150-3364-1942-9447', 4334235.000000, 'uEhMrrC3m1', 'S', NULL, NULL, NULL, NULL, 669);
INSERT INTO cuenta VALUES ('4733-4261-5665-4341', 2898281.000000, 'gc7aBiBpJI6', 'S', NULL, NULL, NULL, NULL, 47);
INSERT INTO cuenta VALUES ('3557-3575-4537-8359', 894086.000000, '5cvOE1Y', 'S', NULL, NULL, NULL, NULL, 751);
INSERT INTO cuenta VALUES ('6448-5532-8595-9876', 8678217.000000, 'iGNJIYkAst', 'S', NULL, NULL, NULL, NULL, 604);
INSERT INTO cuenta VALUES ('6774-6974-3769-8661', 510278.000000, 'w0N4kRE', 'S', NULL, NULL, NULL, NULL, 844);
INSERT INTO cuenta VALUES ('2463-6011-9816-6579', 3452104.000000, 'LAzd9dPPAD', 'S', NULL, NULL, NULL, NULL, 270);
INSERT INTO cuenta VALUES ('9540-1500-6219-2601', 3739950.000000, 'GOhTrB1', 'S', NULL, NULL, NULL, NULL, 527);
INSERT INTO cuenta VALUES ('6232-8206-4165-9327', 4680366.000000, 'teD2nogxzH', 'S', NULL, NULL, NULL, NULL, 562);
INSERT INTO cuenta VALUES ('6563-1983-8686-4351', 8887605.000000, 'QoagOtBUk4', 'S', NULL, NULL, NULL, NULL, 775);
INSERT INTO cuenta VALUES ('4921-8678-5491-7144', 8207291.000000, 'UU9foXzgn', 'S', NULL, NULL, NULL, NULL, 121);
INSERT INTO cuenta VALUES ('1066-7793-0828-6145', 9295061.000000, '1YARNnFu', 'S', NULL, NULL, NULL, NULL, 213);
INSERT INTO cuenta VALUES ('1397-5527-6345-5276', 8654688.000000, 'oo2nRR', 'S', NULL, NULL, NULL, NULL, 886);
INSERT INTO cuenta VALUES ('9347-3876-5471-8112', 1226477.000000, 'lAHRTnVUr', 'S', NULL, NULL, NULL, NULL, 649);
INSERT INTO cuenta VALUES ('1353-3973-0204-0942', 9030112.000000, 'dDDmLkN', 'S', NULL, NULL, NULL, NULL, 168);
INSERT INTO cuenta VALUES ('6415-0932-4787-0273', 6361689.000000, 'BNNT4LyFFMN', 'S', NULL, NULL, NULL, NULL, 170);
INSERT INTO cuenta VALUES ('9043-4633-2766-2560', 3144378.000000, 'TXmIAdj25698', 'S', NULL, NULL, NULL, NULL, 937);
INSERT INTO cuenta VALUES ('3696-1147-1977-2640', 5297709.000000, '5gZWf7', 'S', NULL, NULL, NULL, NULL, 265);
INSERT INTO cuenta VALUES ('7364-9296-6206-5427', 7505244.000000, 'gEPptk9tRit', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO cuenta VALUES ('6623-0922-4006-5380', 3109099.000000, 'VfrcpUsiHK8', 'S', NULL, NULL, NULL, NULL, 603);
INSERT INTO cuenta VALUES ('6115-3958-3982-2712', 6001052.000000, 'UHQ4dv5sm', 'S', NULL, NULL, NULL, NULL, 509);
INSERT INTO cuenta VALUES ('3421-7130-4545-6580', 2014891.000000, 'h6o7Hd1', 'S', NULL, NULL, NULL, NULL, 710);
INSERT INTO cuenta VALUES ('9935-3135-5256-0273', 3713385.000000, 'gaCgxmd', 'S', NULL, NULL, NULL, NULL, 85);
INSERT INTO cuenta VALUES ('4894-2684-5200-8339', 1683338.000000, 'ycroN0b', 'S', NULL, NULL, NULL, NULL, 856);
INSERT INTO cuenta VALUES ('6861-6709-6896-5973', 3977875.000000, '77QjLNmf5bJ', 'S', NULL, NULL, NULL, NULL, 521);
INSERT INTO cuenta VALUES ('4848-2514-0162-3046', 4491202.000000, '5oi69s', 'S', NULL, NULL, NULL, NULL, 576);
INSERT INTO cuenta VALUES ('3910-4552-0763-5927', 9786575.000000, 'AGi4sMWURn', 'S', NULL, NULL, NULL, NULL, 34);
INSERT INTO cuenta VALUES ('6088-2470-4906-4397', 9063297.000000, 'QSjelS', 'S', NULL, NULL, NULL, NULL, 538);
INSERT INTO cuenta VALUES ('9219-5358-5849-6429', 2557999.000000, 'CcKTtx5s', 'S', NULL, NULL, NULL, NULL, 102);
INSERT INTO cuenta VALUES ('3658-9493-3975-7494', 8496519.000000, 'ukhT05UB8', 'S', NULL, NULL, NULL, NULL, 374);
INSERT INTO cuenta VALUES ('7520-2675-5163-0286', 8324695.000000, 'Mi1Fy5uBXee', 'S', NULL, NULL, NULL, NULL, 290);
INSERT INTO cuenta VALUES ('8534-9079-8573-8062', 4311175.000000, 'mOvYdyF23k', 'S', NULL, NULL, NULL, NULL, 180);
INSERT INTO cuenta VALUES ('4495-5579-2472-4106', 9134055.000000, 'FOkvO1lhC', 'S', NULL, NULL, NULL, NULL, 304);
INSERT INTO cuenta VALUES ('3755-5087-4434-7953', 9069097.000000, 'l7muKwZicAB', 'S', NULL, NULL, NULL, NULL, 542);
INSERT INTO cuenta VALUES ('7319-8112-8024-5551', 4619240.000000, 'wOSDak2bT', 'S', NULL, NULL, NULL, NULL, 178);
INSERT INTO cuenta VALUES ('1484-1965-7968-8302', 8531955.000000, 'Aj24pyXwEs', 'S', NULL, NULL, NULL, NULL, 68);
INSERT INTO cuenta VALUES ('7775-0409-8635-7618', 7825840.000000, 'vq8PklX36', 'S', NULL, NULL, NULL, NULL, 886);
INSERT INTO cuenta VALUES ('4671-9760-2734-9146', 8349305.000000, 'mZIRTXtS8eS', 'S', NULL, NULL, NULL, NULL, 517);
INSERT INTO cuenta VALUES ('5011-3643-9067-4650', 6640101.000000, '8LpvlO4gU', 'S', NULL, NULL, NULL, NULL, 224);
INSERT INTO cuenta VALUES ('5313-9962-3772-7428', 6603572.000000, 'PiVvEfZ', 'S', NULL, NULL, NULL, NULL, 276);
INSERT INTO cuenta VALUES ('5405-9690-3813-0623', 2702791.000000, 'oWqL2j8tZp', 'S', NULL, NULL, NULL, NULL, 814);
INSERT INTO cuenta VALUES ('8952-1128-9943-9564', 4913810.000000, '7mtZN6vQU7k', 'S', NULL, NULL, NULL, NULL, 35);
INSERT INTO cuenta VALUES ('1146-7288-7910-4208', 5642773.000000, 'uyu1Y6iDbFEL', 'S', NULL, NULL, NULL, NULL, 885);
INSERT INTO cuenta VALUES ('4689-1922-7607-2338', 4735409.000000, 'U1I4tIF', 'S', NULL, NULL, NULL, NULL, 778);
INSERT INTO cuenta VALUES ('6509-1774-5442-8643', 5150856.000000, 'JskJZrkzeJm', 'S', NULL, NULL, NULL, NULL, 443);
INSERT INTO cuenta VALUES ('3214-9650-7722-9586', 3905895.000000, '4yfCwIc', 'S', NULL, NULL, NULL, NULL, 727);
INSERT INTO cuenta VALUES ('5454-7769-6802-9389', 8281937.000000, 'odlIxFKw7', 'S', NULL, NULL, NULL, NULL, 112);
INSERT INTO cuenta VALUES ('1317-2584-4674-5284', 5870340.000000, 'xrLZyUNXYge', 'S', NULL, NULL, NULL, NULL, 897);
INSERT INTO cuenta VALUES ('5730-9724-1595-6211', 5604941.000000, 'TKUlzstCCi', 'S', NULL, NULL, NULL, NULL, 157);
INSERT INTO cuenta VALUES ('0069-9507-9459-5342', 7188568.000000, '53uZw4DMGv', 'S', NULL, NULL, NULL, NULL, 266);
INSERT INTO cuenta VALUES ('3005-7694-4093-6912', 3020287.000000, 'vNsf6ue', 'S', NULL, NULL, NULL, NULL, 271);
INSERT INTO cuenta VALUES ('8286-4218-5733-4506', 5379862.000000, 'FlQVBK', 'S', NULL, NULL, NULL, NULL, 838);
INSERT INTO cuenta VALUES ('5292-1804-0301-3000', 1075481.000000, 'HXvQsepR0N', 'S', NULL, NULL, NULL, NULL, 891);
INSERT INTO cuenta VALUES ('3713-3296-2228-9558', 9885994.000000, 'uZZYMd', 'S', NULL, NULL, NULL, NULL, 45);
INSERT INTO cuenta VALUES ('5285-6482-4633-6960', 1793694.000000, 'jUNDk0', 'S', NULL, NULL, NULL, NULL, 471);
INSERT INTO cuenta VALUES ('1307-7705-6508-9504', 937521.000000, 'qnx6cvby51JC', 'S', NULL, NULL, NULL, NULL, 622);
INSERT INTO cuenta VALUES ('5720-6749-2791-1660', 5344567.000000, 's1mhcfKtD1sP', 'S', NULL, NULL, NULL, NULL, 348);
INSERT INTO cuenta VALUES ('6393-3280-5895-4042', 5828869.000000, 'Evvd0Pqhkp', 'S', NULL, NULL, NULL, NULL, 568);
INSERT INTO cuenta VALUES ('8768-3013-9217-0896', 8763322.000000, 'rtWI1KMqor', 'S', NULL, NULL, NULL, NULL, 940);
INSERT INTO cuenta VALUES ('1921-3945-0134-0660', 6298251.000000, 'zCnbfbpNx5R', 'S', NULL, NULL, NULL, NULL, 380);
INSERT INTO cuenta VALUES ('2290-3036-8761-5007', 8648780.000000, '01i2Pr0vppBa', 'S', NULL, NULL, NULL, NULL, 595);
INSERT INTO cuenta VALUES ('6692-6306-8415-2542', 9320943.000000, 'Pp9gF4', 'S', NULL, NULL, NULL, NULL, 532);
INSERT INTO cuenta VALUES ('1651-0815-2138-0015', 6823513.000000, 'qDg7lTx', 'S', NULL, NULL, NULL, NULL, 641);
INSERT INTO cuenta VALUES ('2910-0785-7410-5605', 7127656.000000, 'O3BNtYmeEDm', 'S', NULL, NULL, NULL, NULL, 713);
INSERT INTO cuenta VALUES ('8327-7556-4183-0960', 1683150.000000, 'bEOQcmPpO', 'S', NULL, NULL, NULL, NULL, 132);
INSERT INTO cuenta VALUES ('5016-9233-3673-6632', 1260110.000000, '71SIXyRySlda', 'S', NULL, NULL, NULL, NULL, 22);
INSERT INTO cuenta VALUES ('0132-6497-0600-6239', 8629427.000000, 'IhjNDnq', 'S', NULL, NULL, NULL, NULL, 913);
INSERT INTO cuenta VALUES ('2950-5891-4108-3252', 3787984.000000, 'MMt5pqJ49O', 'S', NULL, NULL, NULL, NULL, 598);
INSERT INTO cuenta VALUES ('6087-8556-7819-3072', 8983069.000000, 'qtS342o2PyA4', 'S', NULL, NULL, NULL, NULL, 762);
INSERT INTO cuenta VALUES ('0034-6767-4782-7505', 3347935.000000, 'evGXx1', 'S', NULL, NULL, NULL, NULL, 490);
INSERT INTO cuenta VALUES ('7021-4833-9428-2655', 1265908.000000, 'cxAYUE3iP8', 'S', NULL, NULL, NULL, NULL, 436);
INSERT INTO cuenta VALUES ('6208-8780-3775-3092', 4606483.000000, '1FAmlZr2r6EC', 'S', NULL, NULL, NULL, NULL, 739);
INSERT INTO cuenta VALUES ('2320-5937-1023-0672', 906465.000000, 'Vi36O3', 'S', NULL, NULL, NULL, NULL, 894);
INSERT INTO cuenta VALUES ('7310-2298-5096-5125', 7552819.000000, 'W3Dn9pOOKRB', 'S', NULL, NULL, NULL, NULL, 912);
INSERT INTO cuenta VALUES ('1164-3015-2969-2125', 9425084.000000, 'OMdNC68', 'S', NULL, NULL, NULL, NULL, 639);
INSERT INTO cuenta VALUES ('3179-0452-4529-7625', 3652793.000000, 'gnsi7VkbzWQ', 'S', NULL, NULL, NULL, NULL, 697);
INSERT INTO cuenta VALUES ('6207-6176-7282-7275', 8718949.000000, 'ENiofRqE', 'S', NULL, NULL, NULL, NULL, 640);
INSERT INTO cuenta VALUES ('5622-0444-8703-3050', 2368688.000000, 'vLxD19', 'S', NULL, NULL, NULL, NULL, 595);
INSERT INTO cuenta VALUES ('9527-9284-4964-3788', 3308463.000000, 'oHJ4iB', 'S', NULL, NULL, NULL, NULL, 976);
INSERT INTO cuenta VALUES ('6714-8102-3861-3771', 1053069.000000, 'FFae2yWj', 'S', NULL, NULL, NULL, NULL, 772);
INSERT INTO cuenta VALUES ('2031-9572-9142-4323', 2013047.000000, 'UP8Qtz31iv', 'S', NULL, NULL, NULL, NULL, 523);
INSERT INTO cuenta VALUES ('3379-4512-1551-5239', 2667489.000000, 'LnC9sISN6', 'S', NULL, NULL, NULL, NULL, 989);
INSERT INTO cuenta VALUES ('0188-0666-0396-0715', 7112395.000000, 'oAtfcsLh51LL', 'S', NULL, NULL, NULL, NULL, 421);
INSERT INTO cuenta VALUES ('8274-0374-4971-9327', 3209123.000000, 'eJ9BWpukei4X', 'S', NULL, NULL, NULL, NULL, 926);
INSERT INTO cuenta VALUES ('6189-1325-3301-8696', 2345891.000000, 'aVrdgkE', 'S', NULL, NULL, NULL, NULL, 233);
INSERT INTO cuenta VALUES ('1163-1993-0485-6459', 4109560.000000, '4SHGXxNfi', 'S', NULL, NULL, NULL, NULL, 31);
INSERT INTO cuenta VALUES ('9990-7823-1906-7309', 2770414.000000, '7OJGa2RO3I', 'S', NULL, NULL, NULL, NULL, 608);
INSERT INTO cuenta VALUES ('2862-1293-8254-8522', 5594088.000000, 'q6Y0sq', 'S', NULL, NULL, NULL, NULL, 273);
INSERT INTO cuenta VALUES ('0412-9076-5306-0850', 8534803.000000, 'I6C2VoQ5', 'S', NULL, NULL, NULL, NULL, 836);
INSERT INTO cuenta VALUES ('5675-2416-0548-7965', 1681949.000000, 'wnrmR2vP', 'S', NULL, NULL, NULL, NULL, 777);
INSERT INTO cuenta VALUES ('6057-7991-0988-6079', 9681442.000000, 'blVrWo0fxl0', 'S', NULL, NULL, NULL, NULL, 344);
INSERT INTO cuenta VALUES ('5324-0669-8273-4494', 3140608.000000, 'OgGeGzx', 'S', NULL, NULL, NULL, NULL, 938);
INSERT INTO cuenta VALUES ('0311-0015-1322-6639', 9038192.000000, 'ebQU95Um', 'S', NULL, NULL, NULL, NULL, 190);
INSERT INTO cuenta VALUES ('7664-8886-1824-2868', 5328572.000000, 'o7hIQmiPk45F', 'S', NULL, NULL, NULL, NULL, 593);
INSERT INTO cuenta VALUES ('7111-7769-2675-4479', 8170902.000000, 'd37TREvOg', 'S', NULL, NULL, NULL, NULL, 673);
INSERT INTO cuenta VALUES ('3501-7447-2668-2001', 2044125.000000, 'QYzdmpZ0XqsD', 'S', NULL, NULL, NULL, NULL, 697);
INSERT INTO cuenta VALUES ('5604-3399-2646-4547', 6047128.000000, 'IKKWLG7', 'S', NULL, NULL, NULL, NULL, 321);
INSERT INTO cuenta VALUES ('0243-3986-4197-0196', 2701348.000000, 'kHViibUjZhJE', 'S', NULL, NULL, NULL, NULL, 702);
INSERT INTO cuenta VALUES ('4454-2425-6717-7621', 3294172.000000, 'C4iawTwF', 'S', NULL, NULL, NULL, NULL, 138);
INSERT INTO cuenta VALUES ('7199-6447-0133-0588', 8699202.000000, 'rYOnKu8j', 'S', NULL, NULL, NULL, NULL, 419);
INSERT INTO cuenta VALUES ('8448-7824-2542-6094', 8971569.000000, 'ZrNAOBLE2', 'S', NULL, NULL, NULL, NULL, 966);
INSERT INTO cuenta VALUES ('3063-2332-9484-1972', 1933147.000000, '3pfLsW', 'S', NULL, NULL, NULL, NULL, 282);
INSERT INTO cuenta VALUES ('6355-1637-4737-5521', 7907457.000000, 'rGJchw3', 'S', NULL, NULL, NULL, NULL, 446);
INSERT INTO cuenta VALUES ('4705-2968-6181-8725', 2484208.000000, 'EKiWOfV3t6wx', 'S', NULL, NULL, NULL, NULL, 340);
INSERT INTO cuenta VALUES ('2692-0304-5012-4195', 6004714.000000, 'uesMsYDt8F', 'S', NULL, NULL, NULL, NULL, 151);
INSERT INTO cuenta VALUES ('4888-7712-1193-5149', 8857685.000000, 'jFm2RBTCN', 'S', NULL, NULL, NULL, NULL, 616);
INSERT INTO cuenta VALUES ('4686-0722-1165-5317', 3031553.000000, 'vmxW9X', 'S', NULL, NULL, NULL, NULL, 841);
INSERT INTO cuenta VALUES ('9907-6831-5069-5329', 3343717.000000, 'ckdYFc', 'S', NULL, NULL, NULL, NULL, 194);
INSERT INTO cuenta VALUES ('5513-8716-8473-3032', 1067800.000000, 'YKu5wFYAWF', 'S', NULL, NULL, NULL, NULL, 318);
INSERT INTO cuenta VALUES ('1700-5279-7061-9331', 6365670.000000, 'ugQb4MS3RT1', 'S', NULL, NULL, NULL, NULL, 536);
INSERT INTO cuenta VALUES ('3880-1548-1519-0814', 2133647.000000, 'QHBbch2j', 'S', NULL, NULL, NULL, NULL, 764);
INSERT INTO cuenta VALUES ('0540-6946-0328-5131', 6457299.000000, '513Zvq7oZJT5', 'S', NULL, NULL, NULL, NULL, 643);
INSERT INTO cuenta VALUES ('3083-3029-2488-7313', 1084646.000000, 'fp2mv5ht971', 'S', NULL, NULL, NULL, NULL, 292);
INSERT INTO cuenta VALUES ('0409-8459-2718-2103', 7458319.000000, 'wnviY7x3n', 'S', NULL, NULL, NULL, NULL, 87);
INSERT INTO cuenta VALUES ('3479-1726-5080-7363', 1704923.000000, 'IroDb1Ga', 'S', NULL, NULL, NULL, NULL, 604);
INSERT INTO cuenta VALUES ('9508-5212-7364-1096', 3385952.000000, 'HYdoV7', 'S', NULL, NULL, NULL, NULL, 87);
INSERT INTO cuenta VALUES ('6353-1648-6727-2649', 1739882.000000, 'sQ3BUtOcq', 'S', NULL, NULL, NULL, NULL, 513);
INSERT INTO cuenta VALUES ('5846-6762-5840-0406', 4041793.000000, 'Zj4tQI2Z', 'S', NULL, NULL, NULL, NULL, 507);
INSERT INTO cuenta VALUES ('1573-5688-0766-7384', 6783252.000000, '0Fsu9as2', 'S', NULL, NULL, NULL, NULL, 401);
INSERT INTO cuenta VALUES ('2348-4248-8767-7422', 5748383.000000, 'len3dLGn2nXN', 'S', NULL, NULL, NULL, NULL, 909);
INSERT INTO cuenta VALUES ('5761-8817-9317-3584', 5065092.000000, 'TAueXPiahOas', 'S', NULL, NULL, NULL, NULL, 592);
INSERT INTO cuenta VALUES ('3044-2294-1208-3543', 6696799.000000, 'nFj9PUC', 'S', NULL, NULL, NULL, NULL, 233);
INSERT INTO cuenta VALUES ('0077-4567-1657-4860', 5712488.000000, 'b5GGjpp', 'S', NULL, NULL, NULL, NULL, 43);
INSERT INTO cuenta VALUES ('9157-0006-8482-7328', 9932294.000000, 'JVogvSG', 'S', NULL, NULL, NULL, NULL, 603);
INSERT INTO cuenta VALUES ('1960-4685-1910-8061', 9449687.000000, 'XWv5au', 'S', NULL, NULL, NULL, NULL, 162);
INSERT INTO cuenta VALUES ('2812-4682-7762-8843', 494131.000000, 'TSE3gXUwGe', 'S', NULL, NULL, NULL, NULL, 38);
INSERT INTO cuenta VALUES ('6764-5758-6430-5510', 8585556.000000, 'c8fprX', 'S', NULL, NULL, NULL, NULL, 292);
INSERT INTO cuenta VALUES ('4616-3654-7833-8663', 7774564.000000, 'LHGfC6Zv', 'S', NULL, NULL, NULL, NULL, 876);
INSERT INTO cuenta VALUES ('5323-9980-8465-4107', 9635110.000000, '12fhfFgDab', 'S', NULL, NULL, NULL, NULL, 239);
INSERT INTO cuenta VALUES ('9328-4197-9730-5971', 302438.000000, 'jqhV94IX', 'S', NULL, NULL, NULL, NULL, 801);
INSERT INTO cuenta VALUES ('6544-8611-6302-4110', 1287187.000000, 'EcHIBee1i3GO', 'S', NULL, NULL, NULL, NULL, 398);
INSERT INTO cuenta VALUES ('4627-1760-8303-0896', 4350090.000000, 'mhOBQrofD', 'S', NULL, NULL, NULL, NULL, 939);
INSERT INTO cuenta VALUES ('5915-4957-3150-2232', 3811092.000000, 'wynkGRI', 'S', NULL, NULL, NULL, NULL, 135);
INSERT INTO cuenta VALUES ('2253-6811-3757-0245', 4464139.000000, 'Z6vWmz', 'S', NULL, NULL, NULL, NULL, 268);
INSERT INTO cuenta VALUES ('2818-2676-2084-5303', 8194179.000000, 'icbhwa7ly', 'S', NULL, NULL, NULL, NULL, 777);
INSERT INTO cuenta VALUES ('9049-7264-5388-1922', 4269692.000000, 't87KzMTI6T', 'S', NULL, NULL, NULL, NULL, 321);
INSERT INTO cuenta VALUES ('6740-0549-2633-5376', 7562708.000000, 'VFaTb13', 'S', NULL, NULL, NULL, NULL, 740);
INSERT INTO cuenta VALUES ('0098-7427-1422-1609', 2759482.000000, 'YwY266uEn', 'S', NULL, NULL, NULL, NULL, 7);
INSERT INTO cuenta VALUES ('9101-1561-3276-6523', 1527007.000000, 'wtpCCMsfHI', 'S', NULL, NULL, NULL, NULL, 670);
INSERT INTO cuenta VALUES ('9663-4910-6193-3076', 1535948.000000, '82WTTVdwiJ', 'S', NULL, NULL, NULL, NULL, 678);
INSERT INTO cuenta VALUES ('1394-5072-6957-1254', 5537732.000000, 'qrr1fSL', 'S', NULL, NULL, NULL, NULL, 885);
INSERT INTO cuenta VALUES ('9154-2697-9195-6081', 8092349.000000, '11Oe53kV', 'S', NULL, NULL, NULL, NULL, 967);
INSERT INTO cuenta VALUES ('0197-7049-8668-0045', 8292116.000000, 'MAKUlCNC5', 'S', NULL, NULL, NULL, NULL, 100);
INSERT INTO cuenta VALUES ('7105-1574-8211-1915', 9052733.000000, 'SBs2Wby2', 'S', NULL, NULL, NULL, NULL, 499);
INSERT INTO cuenta VALUES ('0551-7162-2876-5765', 5775764.000000, 'MBYr3Nn4', 'S', NULL, NULL, NULL, NULL, 495);
INSERT INTO cuenta VALUES ('0296-3455-9237-9389', 507106.000000, 'O2tK5s', 'S', NULL, NULL, NULL, NULL, 177);
INSERT INTO cuenta VALUES ('8453-9773-4081-3459', 8917849.000000, 'ClJC4Jrg4D4', 'S', NULL, NULL, NULL, NULL, 75);
INSERT INTO cuenta VALUES ('4858-8039-0948-4661', 3472684.000000, 'MAo8fJUM', 'S', NULL, NULL, NULL, NULL, 390);
INSERT INTO cuenta VALUES ('7782-9013-3604-8608', 2951191.000000, 'lqpu1H0', 'S', NULL, NULL, NULL, NULL, 577);
INSERT INTO cuenta VALUES ('4743-3531-8778-5660', 3646245.000000, 'oRo0WMkJpP', 'S', NULL, NULL, NULL, NULL, 429);
INSERT INTO cuenta VALUES ('4771-2037-7037-4114', 8684376.000000, 'fRIU2M', 'S', NULL, NULL, NULL, NULL, 188);
INSERT INTO cuenta VALUES ('5118-7796-3318-5074', 9091455.000000, 'nJTafP', 'S', NULL, NULL, NULL, NULL, 218);
INSERT INTO cuenta VALUES ('0547-5029-4516-4376', 6643917.000000, 'ecXbq322cVR', 'S', NULL, NULL, NULL, NULL, 509);
INSERT INTO cuenta VALUES ('9088-7047-4383-0951', 7912286.000000, 'K0Em5hAHWIZl', 'S', NULL, NULL, NULL, NULL, 614);
INSERT INTO cuenta VALUES ('7095-9359-3978-8415', 4685785.000000, 'HVGJAMHJO', 'S', NULL, NULL, NULL, NULL, 137);
INSERT INTO cuenta VALUES ('2570-5079-1604-4732', 4470347.000000, 'aMfankER9Jas', 'S', NULL, NULL, NULL, NULL, 509);
INSERT INTO cuenta VALUES ('8565-8749-7623-8424', 1888353.000000, '6OzkH1E479K', 'S', NULL, NULL, NULL, NULL, 825);
INSERT INTO cuenta VALUES ('9756-9885-2500-2562', 4558023.000000, '3xVOo9cE', 'S', NULL, NULL, NULL, NULL, 823);
INSERT INTO cuenta VALUES ('5923-5263-3802-9690', 7162586.000000, 'pXLtJLDtQc', 'S', NULL, NULL, NULL, NULL, 23);
INSERT INTO cuenta VALUES ('3016-5675-9913-8007', 2775630.000000, 'pdFxxmYZ0QAi', 'S', NULL, NULL, NULL, NULL, 145);
INSERT INTO cuenta VALUES ('7902-8423-1078-5428', 3302855.000000, '3RLZ50J1', 'S', NULL, NULL, NULL, NULL, 62);
INSERT INTO cuenta VALUES ('0367-2672-6297-4173', 2767731.000000, 'yWX5I2jk7oz', 'S', NULL, NULL, NULL, NULL, 870);
INSERT INTO cuenta VALUES ('8163-2482-0742-4703', 964039.000000, 'odZVhzGJ9L', 'S', NULL, NULL, NULL, NULL, 813);
INSERT INTO cuenta VALUES ('2489-5481-2091-0546', 9305433.000000, '2kmSpTkSBoHK', 'S', NULL, NULL, NULL, NULL, 938);
INSERT INTO cuenta VALUES ('9644-8142-3239-0333', 5149654.000000, 'EdNpDnPQX7', 'S', NULL, NULL, NULL, NULL, 381);
INSERT INTO cuenta VALUES ('0192-5479-6096-5021', 7159899.000000, 'PTX6bJ', 'S', NULL, NULL, NULL, NULL, 188);
INSERT INTO cuenta VALUES ('6417-5929-4715-9607', 8929590.000000, 'kWwn0Gf', 'S', NULL, NULL, NULL, NULL, 875);
INSERT INTO cuenta VALUES ('3046-9363-8774-0128', 6770883.000000, 'P3tr1LU', 'S', NULL, NULL, NULL, NULL, 52);
INSERT INTO cuenta VALUES ('5946-6733-5502-3728', 6820748.000000, '9AcT5Hn', 'S', NULL, NULL, NULL, NULL, 395);
INSERT INTO cuenta VALUES ('3922-8422-5749-7059', 3726294.000000, 'oIUbiZSq', 'S', NULL, NULL, NULL, NULL, 100);
INSERT INTO cuenta VALUES ('4137-5168-1162-9932', 5061390.000000, 'D65hWbEH', 'S', NULL, NULL, NULL, NULL, 419);
INSERT INTO cuenta VALUES ('7537-1733-7422-2789', 7427889.000000, 'hafbhr', 'S', NULL, NULL, NULL, NULL, 126);
INSERT INTO cuenta VALUES ('2621-8071-0596-0725', 6948126.000000, 'CtTeY2', 'S', NULL, NULL, NULL, NULL, 43);
INSERT INTO cuenta VALUES ('5824-3816-5646-3853', 7128784.000000, 'cXQ42VYsEE', 'S', NULL, NULL, NULL, NULL, 362);
INSERT INTO cuenta VALUES ('4567-1348-7465-0872', 908401.000000, 'sak0nkXC', 'S', NULL, NULL, NULL, NULL, 193);
INSERT INTO cuenta VALUES ('4427-2982-3924-9906', 4313854.000000, 'rwsFjHKQ8ToM', 'S', NULL, NULL, NULL, NULL, 846);
INSERT INTO cuenta VALUES ('5640-7357-3283-2720', 3085547.000000, 'WGwxEJq', 'S', NULL, NULL, NULL, NULL, 377);
INSERT INTO cuenta VALUES ('2239-0021-0747-5931', 1132833.000000, 'lDHM1oHM', 'S', NULL, NULL, NULL, NULL, 645);
INSERT INTO cuenta VALUES ('1878-8868-4340-8033', 7783184.000000, 'o0JQBzwPsTs', 'S', NULL, NULL, NULL, NULL, 354);
INSERT INTO cuenta VALUES ('7849-9852-1988-8185', 3528953.000000, 'M52LglJC', 'S', NULL, NULL, NULL, NULL, 121);
INSERT INTO cuenta VALUES ('0421-1925-4530-7948', 4280673.000000, 'JhOUPkyAg', 'S', NULL, NULL, NULL, NULL, 258);
INSERT INTO cuenta VALUES ('4482-2560-2227-6414', 4433189.000000, 'nhc9YxfUq', 'S', NULL, NULL, NULL, NULL, 129);
INSERT INTO cuenta VALUES ('6431-7474-5737-4763', 3541177.000000, 'xVlmZIbH', 'S', NULL, NULL, NULL, NULL, 73);
INSERT INTO cuenta VALUES ('1662-3823-4602-2335', 4259442.000000, 'larKnDwfo', 'S', NULL, NULL, NULL, NULL, 947);
INSERT INTO cuenta VALUES ('4512-9276-3911-1507', 5287841.000000, 'fbWPLU7', 'S', NULL, NULL, NULL, NULL, 730);
INSERT INTO cuenta VALUES ('5685-1319-7765-2267', 2208722.000000, 'Veabad', 'S', NULL, NULL, NULL, NULL, 539);
INSERT INTO cuenta VALUES ('9212-7044-2957-9181', 2277650.000000, 'lYTJcMa6', 'S', NULL, NULL, NULL, NULL, 844);
INSERT INTO cuenta VALUES ('0051-9076-0761-5793', 5275557.000000, '6QMy0350r', 'S', NULL, NULL, NULL, NULL, 522);
INSERT INTO cuenta VALUES ('2231-9833-2577-5209', 6299508.000000, '9I3CsUZKK7l', 'S', NULL, NULL, NULL, NULL, 284);
INSERT INTO cuenta VALUES ('9410-4332-7594-0955', 4381276.000000, 'YunIgvsnCmBn', 'S', NULL, NULL, NULL, NULL, 92);
INSERT INTO cuenta VALUES ('3009-4495-7599-4205', 967966.000000, 'aEVOrdozpF', 'S', NULL, NULL, NULL, NULL, 830);
INSERT INTO cuenta VALUES ('6216-9358-8782-4810', 1590303.000000, 'DgqHUh8Hm', 'S', NULL, NULL, NULL, NULL, 617);
INSERT INTO cuenta VALUES ('9572-1724-3943-7707', 6275953.000000, 'q3g9Swj3O0GF', 'S', NULL, NULL, NULL, NULL, 404);
INSERT INTO cuenta VALUES ('5477-4578-5978-8513', 2354291.000000, '51W3jPWF', 'S', NULL, NULL, NULL, NULL, 210);
INSERT INTO cuenta VALUES ('3497-9374-7298-4918', 2365245.000000, 'hIBC86MzFOfL', 'S', NULL, NULL, NULL, NULL, 676);
INSERT INTO cuenta VALUES ('9053-0850-4470-1740', 5346180.000000, 'HmJoVkBh3HF', 'S', NULL, NULL, NULL, NULL, 996);
INSERT INTO cuenta VALUES ('9185-5566-6660-8411', 1407892.000000, 'kmSOYGfcV5R', 'S', NULL, NULL, NULL, NULL, 524);
INSERT INTO cuenta VALUES ('7967-3109-8551-0298', 1683061.000000, 'hBkAzf', 'S', NULL, NULL, NULL, NULL, 884);
INSERT INTO cuenta VALUES ('4580-0098-1009-8006', 9588072.000000, '7RS6uwfRjs', 'S', NULL, NULL, NULL, NULL, 681);
INSERT INTO cuenta VALUES ('3581-6643-0457-5720', 5101154.000000, 'b0Jas2', 'S', NULL, NULL, NULL, NULL, 700);
INSERT INTO cuenta VALUES ('2219-9194-0281-5071', 408282.000000, 'nwVkB2mdYGg', 'S', NULL, NULL, NULL, NULL, 645);
INSERT INTO cuenta VALUES ('7721-3935-7760-9093', 352879.000000, 'yinFY0', 'S', NULL, NULL, NULL, NULL, 50);
INSERT INTO cuenta VALUES ('1189-5630-1041-7694', 800361.000000, 'M1LrouZAS', 'S', NULL, NULL, NULL, NULL, 285);
INSERT INTO cuenta VALUES ('8999-7740-0760-4407', 2930908.000000, '9O8xlp', 'S', NULL, NULL, NULL, NULL, 489);
INSERT INTO cuenta VALUES ('3076-3973-3237-6868', 1543353.000000, 'KB91y5p', 'S', NULL, NULL, NULL, NULL, 114);
INSERT INTO cuenta VALUES ('9607-8137-2531-2771', 9010291.000000, 'y4jhGo0', 'S', NULL, NULL, NULL, NULL, 383);
INSERT INTO cuenta VALUES ('3400-3752-1147-8866', 7539687.000000, 'qA7QZp88Xjg4', 'S', NULL, NULL, NULL, NULL, 604);
INSERT INTO cuenta VALUES ('3717-0900-9045-1028', 6500179.000000, '7wk5IDJWM', 'S', NULL, NULL, NULL, NULL, 916);
INSERT INTO cuenta VALUES ('5084-7263-1415-1320', 5829160.000000, 'NbMhkvcZVl', 'S', NULL, NULL, NULL, NULL, 75);
INSERT INTO cuenta VALUES ('5485-7524-9734-7416', 3605143.000000, 'SimEYjI8', 'S', NULL, NULL, NULL, NULL, 422);
INSERT INTO cuenta VALUES ('0251-0149-0515-1205', 5286206.000000, 'AbhUhArELWy', 'S', NULL, NULL, NULL, NULL, 494);
INSERT INTO cuenta VALUES ('4932-4864-2741-1392', 455114.000000, 'A2Km1TM4X3nv', 'S', NULL, NULL, NULL, NULL, 957);
INSERT INTO cuenta VALUES ('5170-0044-2117-4298', 5701604.000000, 'uGwrix8Zd', 'S', NULL, NULL, NULL, NULL, 87);
INSERT INTO cuenta VALUES ('2820-4250-2631-7760', 4287767.000000, 'lpreOgY', 'S', NULL, NULL, NULL, NULL, 580);
INSERT INTO cuenta VALUES ('5978-3860-8632-9785', 2745007.000000, 'KERPBbmjgx3', 'S', NULL, NULL, NULL, NULL, 920);
INSERT INTO cuenta VALUES ('2787-2166-4230-4736', 9927381.000000, 'wM8gxgewR0e7', 'S', NULL, NULL, NULL, NULL, 620);
INSERT INTO cuenta VALUES ('5177-6863-6586-2757', 8071678.000000, 'xNuYZT', 'S', NULL, NULL, NULL, NULL, 845);
INSERT INTO cuenta VALUES ('4242-1879-1883-1502', 5906722.000000, 'VvtHPLufdz', 'S', NULL, NULL, NULL, NULL, 17);
INSERT INTO cuenta VALUES ('3922-0971-0048-6047', 7439721.000000, 'y8UWBymezVkm', 'S', NULL, NULL, NULL, NULL, 138);
INSERT INTO cuenta VALUES ('4459-9439-1474-9340', 8514390.000000, 'j5w3MYmUff1', 'S', NULL, NULL, NULL, NULL, 970);
INSERT INTO cuenta VALUES ('5528-8341-1658-5286', 5153219.000000, '4A9UAKpAvIB', 'S', NULL, NULL, NULL, NULL, 417);
INSERT INTO cuenta VALUES ('5633-7882-1806-5575', 9980076.000000, 'HiADBoa', 'S', NULL, NULL, NULL, NULL, 125);
INSERT INTO cuenta VALUES ('4708-6178-0188-8981', 7082412.000000, '9ENb4Gr4XB', 'S', NULL, NULL, NULL, NULL, 494);
INSERT INTO cuenta VALUES ('6731-0185-1983-1012', 6145578.000000, 'boaqueK', 'S', NULL, NULL, NULL, NULL, 153);
INSERT INTO cuenta VALUES ('8258-5914-2005-3290', 2614764.000000, '6La5Z4vR5U', 'S', NULL, NULL, NULL, NULL, 938);
INSERT INTO cuenta VALUES ('9948-4956-7378-3493', 6466297.000000, 'VaCy3oamwLaA', 'S', NULL, NULL, NULL, NULL, 800);
INSERT INTO cuenta VALUES ('2245-7764-3784-3063', 9272571.000000, 'I4FJZCp', 'S', NULL, NULL, NULL, NULL, 96);
INSERT INTO cuenta VALUES ('1309-5302-4253-5059', 3357281.000000, 'DEInaNJD7Ah', 'S', NULL, NULL, NULL, NULL, 579);
INSERT INTO cuenta VALUES ('0967-5264-8820-9709', 4782352.000000, 'rBzPva', 'S', NULL, NULL, NULL, NULL, 107);
INSERT INTO cuenta VALUES ('3568-4061-4004-1135', 8675887.000000, 'dgjhX7', 'S', NULL, NULL, NULL, NULL, 853);
INSERT INTO cuenta VALUES ('9492-7222-9595-2662', 959562.000000, 'BYFxhCOkc', 'S', NULL, NULL, NULL, NULL, 754);
INSERT INTO cuenta VALUES ('4174-1075-9926-1188', 5655140.000000, 'CNR9ietd', 'S', NULL, NULL, NULL, NULL, 819);
INSERT INTO cuenta VALUES ('4854-3923-6756-6536', 4873234.000000, '6lj4PbOtV', 'S', NULL, NULL, NULL, NULL, 544);
INSERT INTO cuenta VALUES ('9741-6506-2020-9339', 3471325.000000, 'npIhWuaN', 'S', NULL, NULL, NULL, NULL, 903);
INSERT INTO cuenta VALUES ('8564-1156-3160-7082', 2044039.000000, 'JlMsjXvxBQZ', 'S', NULL, NULL, NULL, NULL, 701);
INSERT INTO cuenta VALUES ('9129-3912-3235-2319', 1835556.000000, '1pcUtl7ZNpg', 'S', NULL, NULL, NULL, NULL, 335);
INSERT INTO cuenta VALUES ('1451-3810-8563-3199', 9977756.000000, 'z2iNjmul2z', 'S', NULL, NULL, NULL, NULL, 149);
INSERT INTO cuenta VALUES ('9891-9499-9581-6067', 7077458.000000, 'uOQs5Bq', 'S', NULL, NULL, NULL, NULL, 137);
INSERT INTO cuenta VALUES ('0330-2262-7436-8183', 3913678.000000, 'c2d80VC', 'S', NULL, NULL, NULL, NULL, 429);
INSERT INTO cuenta VALUES ('4663-9049-2156-9234', 7236682.000000, 'rj3TJsYOMGq', 'S', NULL, NULL, NULL, NULL, 529);
INSERT INTO cuenta VALUES ('0984-4498-2183-0918', 1928015.000000, 'jsDdiNmHsg', 'S', NULL, NULL, NULL, NULL, 112);
INSERT INTO cuenta VALUES ('1913-9586-0083-4864', 9832419.000000, 'iJWi2RZQv', 'S', NULL, NULL, NULL, NULL, 767);
INSERT INTO cuenta VALUES ('6035-9598-7734-1311', 6744798.000000, 'YXhnhefsjpRl', 'S', NULL, NULL, NULL, NULL, 116);
INSERT INTO cuenta VALUES ('3781-7167-2657-4565', 1514689.000000, '1vI2XP', 'S', NULL, NULL, NULL, NULL, 513);
INSERT INTO cuenta VALUES ('1781-0935-7759-7121', 6927809.000000, 'UeUxY6', 'S', NULL, NULL, NULL, NULL, 569);
INSERT INTO cuenta VALUES ('6230-1816-5832-9935', 7547589.000000, 'A9sOzmvvd', 'S', NULL, NULL, NULL, NULL, 327);
INSERT INTO cuenta VALUES ('4418-8614-8382-1524', 462623.000000, 'RPKU5d', 'S', NULL, NULL, NULL, NULL, 445);
INSERT INTO cuenta VALUES ('5196-0137-9489-3674', 5833584.000000, '58P4M5RE80tH', 'S', NULL, NULL, NULL, NULL, 755);
INSERT INTO cuenta VALUES ('1863-5259-7231-6792', 939913.000000, 'tm5TJFgBkphT', 'S', NULL, NULL, NULL, NULL, 249);
INSERT INTO cuenta VALUES ('9345-9886-7581-3849', 6536217.000000, 'r7BchTxa', 'S', NULL, NULL, NULL, NULL, 977);
INSERT INTO cuenta VALUES ('6404-6150-7798-0070', 5487546.000000, 'EK2CTyb', 'S', NULL, NULL, NULL, NULL, 980);
INSERT INTO cuenta VALUES ('8491-2030-8852-6202', 7930331.000000, 'wTW3WKreX', 'S', NULL, NULL, NULL, NULL, 734);
INSERT INTO cuenta VALUES ('7206-1116-2261-6197', 9239808.000000, '1MYOTGqY6H', 'S', NULL, NULL, NULL, NULL, 43);
INSERT INTO cuenta VALUES ('9372-0671-4315-2857', 5157928.000000, '2I2q1R', 'S', NULL, NULL, NULL, NULL, 371);
INSERT INTO cuenta VALUES ('7409-6529-5832-1242', 4400002.000000, 'TTyWasbo', 'S', NULL, NULL, NULL, NULL, 863);
INSERT INTO cuenta VALUES ('2821-2474-4076-6607', 8794977.000000, 'sgKT3F', 'S', NULL, NULL, NULL, NULL, 547);
INSERT INTO cuenta VALUES ('6177-8211-0494-2561', 1493955.000000, '0U7m8M427uBV', 'S', NULL, NULL, NULL, NULL, 723);
INSERT INTO cuenta VALUES ('7830-8553-6148-0312', 3291264.000000, 'jEH1dWWU', 'S', NULL, NULL, NULL, NULL, 607);
INSERT INTO cuenta VALUES ('1074-7415-6736-1342', 6116880.000000, '8Kls5Npfns', 'S', NULL, NULL, NULL, NULL, 336);
INSERT INTO cuenta VALUES ('0788-8037-2846-3626', 1942167.000000, 'n4nDqrD1dfCm', 'S', NULL, NULL, NULL, NULL, 240);
INSERT INTO cuenta VALUES ('5978-3984-5202-6244', 2920506.000000, 'SVFKyPO', 'S', NULL, NULL, NULL, NULL, 30);
INSERT INTO cuenta VALUES ('9289-7005-5414-1159', 3443559.000000, 'UgD8yZyRZs', 'S', NULL, NULL, NULL, NULL, 136);
INSERT INTO cuenta VALUES ('6342-7068-6265-9033', 8683625.000000, 'kwhcowM', 'S', NULL, NULL, NULL, NULL, 774);
INSERT INTO cuenta VALUES ('0053-1676-8840-0050', 3447385.000000, 'V9vApygOeu', 'S', NULL, NULL, NULL, NULL, 867);
INSERT INTO cuenta VALUES ('3270-9866-3123-0033', 6249448.000000, 'qaiwbR0n', 'S', NULL, NULL, NULL, NULL, 148);
INSERT INTO cuenta VALUES ('2958-2560-2669-3583', 1211611.000000, '8SlR1PydMjA', 'S', NULL, NULL, NULL, NULL, 874);
INSERT INTO cuenta VALUES ('4020-6789-8929-1474', 3998683.000000, 'lRCUUXN1SC', 'S', NULL, NULL, NULL, NULL, 802);
INSERT INTO cuenta VALUES ('0808-6074-5322-0970', 4717141.000000, 'Xaj06GQ5AhQM', 'S', NULL, NULL, NULL, NULL, 674);
INSERT INTO cuenta VALUES ('9284-3916-9707-0109', 9886542.000000, 'SqCC1b', 'S', NULL, NULL, NULL, NULL, 123);
INSERT INTO cuenta VALUES ('3036-3641-6797-1007', 8478699.000000, 'SgvW8FGfM', 'S', NULL, NULL, NULL, NULL, 130);
INSERT INTO cuenta VALUES ('9564-6606-1095-5070', 3490051.000000, 'v0vYDnF', 'S', NULL, NULL, NULL, NULL, 500);
INSERT INTO cuenta VALUES ('8733-4539-0370-6879', 2076998.000000, 'sf0koW', 'S', NULL, NULL, NULL, NULL, 204);
INSERT INTO cuenta VALUES ('5350-7469-1145-6539', 2235275.000000, '2h4LosOom', 'S', NULL, NULL, NULL, NULL, 650);
INSERT INTO cuenta VALUES ('6220-0661-3454-4293', 5683917.000000, 'PMOeykmSBi', 'S', NULL, NULL, NULL, NULL, 416);
INSERT INTO cuenta VALUES ('4372-1496-2740-4018', 8962180.000000, 'r3dhJSI', 'S', NULL, NULL, NULL, NULL, 89);
INSERT INTO cuenta VALUES ('3682-2458-8140-7763', 4358320.000000, 'I5Sn0GkpTzqd', 'S', NULL, NULL, NULL, NULL, 568);
INSERT INTO cuenta VALUES ('2898-4599-7093-2425', 4483111.000000, 'WzEBcs', 'S', NULL, NULL, NULL, NULL, 394);
INSERT INTO cuenta VALUES ('6980-4414-4235-6931', 5069464.000000, 'i0w0MVD', 'S', NULL, NULL, NULL, NULL, 526);
INSERT INTO cuenta VALUES ('1440-4645-5881-0583', 9039888.000000, 'g7uKo8gCTKBg', 'S', NULL, NULL, NULL, NULL, 425);
INSERT INTO cuenta VALUES ('4814-9390-2719-2302', 857542.000000, 'JzjQChlNj', 'S', NULL, NULL, NULL, NULL, 521);
INSERT INTO cuenta VALUES ('6989-9542-4759-4797', 2658572.000000, 'ETQv30NLL', 'S', NULL, NULL, NULL, NULL, 272);
INSERT INTO cuenta VALUES ('6559-5528-1074-7178', 8670477.000000, '4ZYcgIEXoda', 'S', NULL, NULL, NULL, NULL, 141);
INSERT INTO cuenta VALUES ('6975-5027-5940-3423', 8979114.000000, 'ARA4uRd1kyu', 'S', NULL, NULL, NULL, NULL, 302);
INSERT INTO cuenta VALUES ('6970-2160-1156-9201', 5170863.000000, 'fodm8ox0OgQb', 'S', NULL, NULL, NULL, NULL, 687);
INSERT INTO cuenta VALUES ('7481-9034-3894-1653', 8632250.000000, 'xLYfJAik1E', 'S', NULL, NULL, NULL, NULL, 805);
INSERT INTO cuenta VALUES ('0897-4477-5168-0600', 9755920.000000, 'mIuMKBaF', 'S', NULL, NULL, NULL, NULL, 785);
INSERT INTO cuenta VALUES ('0470-8411-3113-9340', 9725100.000000, 'lCMPbR', 'S', NULL, NULL, NULL, NULL, 82);
INSERT INTO cuenta VALUES ('1912-5142-3782-8070', 2919025.000000, 'y9zUakQS', 'S', NULL, NULL, NULL, NULL, 75);
INSERT INTO cuenta VALUES ('0718-8123-6089-9536', 2499730.000000, 'RiPJ2qB6b9yl', 'S', NULL, NULL, NULL, NULL, 86);
INSERT INTO cuenta VALUES ('2514-2199-0803-8441', 483403.000000, 'UzD3sk', 'S', NULL, NULL, NULL, NULL, 586);
INSERT INTO cuenta VALUES ('5011-9289-2370-5641', 9416210.000000, 'v59tz3SPd', 'S', NULL, NULL, NULL, NULL, 490);
INSERT INTO cuenta VALUES ('1409-5391-7611-1252', 3082899.000000, 'MAoCUyhOm6', 'S', NULL, NULL, NULL, NULL, 493);
INSERT INTO cuenta VALUES ('4781-2747-8556-7173', 6605309.000000, 'Zlpy3qPGm6g', 'S', NULL, NULL, NULL, NULL, 665);
INSERT INTO cuenta VALUES ('6277-6327-6075-0425', 3747866.000000, '999Wfh14', 'S', NULL, NULL, NULL, NULL, 499);
INSERT INTO cuenta VALUES ('1164-6397-1589-7016', 7403450.000000, 'TW6xRg', 'S', NULL, NULL, NULL, NULL, 799);
INSERT INTO cuenta VALUES ('3158-4359-4749-0463', 5376490.000000, 'lMxYrRW5vGa', 'S', NULL, NULL, NULL, NULL, 190);
INSERT INTO cuenta VALUES ('6110-9331-1197-5963', 6279112.000000, 'ptI5AY1Jk0Yh', 'S', NULL, NULL, NULL, NULL, 272);
INSERT INTO cuenta VALUES ('4010-9819-4078-4210', 7214169.000000, 'NC7XIDxkzM', 'S', NULL, NULL, NULL, NULL, 769);
INSERT INTO cuenta VALUES ('2487-2383-6279-7843', 7741586.000000, 'gVktBWbHe', 'S', NULL, NULL, NULL, NULL, 881);
INSERT INTO cuenta VALUES ('8904-6560-5014-0918', 7479628.000000, 'X0gWfSioTu', 'S', NULL, NULL, NULL, NULL, 967);
INSERT INTO cuenta VALUES ('5940-5319-5421-5694', 8390610.000000, 'OO9C6a3iC82n', 'S', NULL, NULL, NULL, NULL, 859);
INSERT INTO cuenta VALUES ('8633-8511-9099-9557', 5015367.000000, 'iGB5km', 'S', NULL, NULL, NULL, NULL, 640);
INSERT INTO cuenta VALUES ('2026-3691-3852-0924', 4418290.000000, 'xkyGDg0jh07x', 'S', NULL, NULL, NULL, NULL, 575);
INSERT INTO cuenta VALUES ('5657-2822-6945-3000', 5587725.000000, 'yeNGd9vqouo9', 'S', NULL, NULL, NULL, NULL, 575);
INSERT INTO cuenta VALUES ('3732-7051-9705-4660', 532726.000000, 'WsaquO6L4QG', 'S', NULL, NULL, NULL, NULL, 553);
INSERT INTO cuenta VALUES ('1139-5952-2644-4942', 9210351.000000, 'PNEHuwU', 'S', NULL, NULL, NULL, NULL, 383);
INSERT INTO cuenta VALUES ('7556-3894-8602-4265', 7969705.000000, 'en91X8nAVLR7', 'S', NULL, NULL, NULL, NULL, 537);
INSERT INTO cuenta VALUES ('6821-9450-9083-1235', 4377918.000000, '90rUorN', 'S', NULL, NULL, NULL, NULL, 130);
INSERT INTO cuenta VALUES ('7347-1549-8692-7579', 1636499.000000, 'DXavQXj9AA7w', 'S', NULL, NULL, NULL, NULL, 18);
INSERT INTO cuenta VALUES ('7277-9522-3744-9251', 8177864.000000, 'aQlPFh2ITn', 'S', NULL, NULL, NULL, NULL, 948);
INSERT INTO cuenta VALUES ('2332-7344-2702-8919', 643297.000000, 'DqNBLnQMlHY', 'S', NULL, NULL, NULL, NULL, 60);
INSERT INTO cuenta VALUES ('7669-6056-3892-7749', 7023659.000000, 'nNq3xm74xxd', 'S', NULL, NULL, NULL, NULL, 853);
INSERT INTO cuenta VALUES ('4486-2800-9767-8984', 1956801.000000, 'qs3FmSTQB', 'S', NULL, NULL, NULL, NULL, 784);
INSERT INTO cuenta VALUES ('1489-8366-8797-6551', 9187452.000000, '987PlpWgtHrc', 'S', NULL, NULL, NULL, NULL, 523);
INSERT INTO cuenta VALUES ('2240-1603-5326-6867', 9574244.000000, 'f2euGtF', 'S', NULL, NULL, NULL, NULL, 739);
INSERT INTO cuenta VALUES ('4108-3446-6246-1465', 4767487.000000, '2Rr5RYSuG', 'S', NULL, NULL, NULL, NULL, 368);
INSERT INTO cuenta VALUES ('4995-1909-4339-0961', 9973193.000000, 'HUxPbmw', 'S', NULL, NULL, NULL, NULL, 213);
INSERT INTO cuenta VALUES ('8872-0836-2802-9273', 8251413.000000, 'lh0RH00', 'S', NULL, NULL, NULL, NULL, 985);
INSERT INTO cuenta VALUES ('8249-9935-9909-0701', 4193464.000000, 'H8lS3O8MB', 'S', NULL, NULL, NULL, NULL, 428);
INSERT INTO cuenta VALUES ('3553-7578-7369-8648', 6070501.000000, 'b5WkVHzx04KA', 'S', NULL, NULL, NULL, NULL, 811);
INSERT INTO cuenta VALUES ('3772-1798-4523-0342', 4884244.000000, 'MkrN88QC0', 'S', NULL, NULL, NULL, NULL, 912);
INSERT INTO cuenta VALUES ('2127-7418-9768-9601', 4735442.000000, 'SUr86Cp6exp', 'S', NULL, NULL, NULL, NULL, 832);
INSERT INTO cuenta VALUES ('1330-1276-9134-4839', 4402574.000000, 'P4UPPgf', 'S', NULL, NULL, NULL, NULL, 705);
INSERT INTO cuenta VALUES ('2809-9982-0252-0943', 2618129.000000, 'vJ7AL42xFx', 'S', NULL, NULL, NULL, NULL, 713);
INSERT INTO cuenta VALUES ('1694-6629-7715-5792', 892073.000000, 'K0kUWB2gEd', 'S', NULL, NULL, NULL, NULL, 195);
INSERT INTO cuenta VALUES ('2120-5875-2353-9365', 6719668.000000, 'xTUiGr', 'S', NULL, NULL, NULL, NULL, 969);
INSERT INTO cuenta VALUES ('9757-8775-0170-6571', 6241582.000000, 'Tn8ZiJG22yf', 'S', NULL, NULL, NULL, NULL, 686);
INSERT INTO cuenta VALUES ('1958-5511-4198-8439', 4119000.000000, '7gaeM5kHS', 'S', NULL, NULL, NULL, NULL, 173);
INSERT INTO cuenta VALUES ('3961-2697-1929-6422', 6053034.000000, 'dcOnM1cYa', 'S', NULL, NULL, NULL, NULL, 842);
INSERT INTO cuenta VALUES ('7393-2010-0449-1833', 2591994.000000, 'yiIfND', 'S', NULL, NULL, NULL, NULL, 693);
INSERT INTO cuenta VALUES ('8710-3663-6240-3632', 2848454.000000, '3L4N0p', 'S', NULL, NULL, NULL, NULL, 27);
INSERT INTO cuenta VALUES ('2241-4361-4909-0695', 2914565.000000, 'iDDakgzSf', 'S', NULL, NULL, NULL, NULL, 838);
INSERT INTO cuenta VALUES ('4707-4351-5513-7836', 4992098.000000, 'ZYeS03LdlZZb', 'S', NULL, NULL, NULL, NULL, 79);
INSERT INTO cuenta VALUES ('5609-7989-4644-3688', 3066843.000000, 'NoyhknF2', 'S', NULL, NULL, NULL, NULL, 377);
INSERT INTO cuenta VALUES ('3992-3343-8699-1754', 6857127.000000, 'drclnsL1ZPKB', 'N', NULL, NULL, NULL, NULL, 463);


--
-- TOC entry 2291 (class 0 OID 35153)
-- Dependencies: 191
-- Data for Name: cuenta_registrada; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO cuenta_registrada VALUES (1, 1, '4640-0341-9387-5781', 'S', NULL, NULL, NULL, NULL);
INSERT INTO cuenta_registrada VALUES (2, 1, '1630-2511-2937-7299', 'S', NULL, NULL, NULL, NULL);
INSERT INTO cuenta_registrada VALUES (3, 1, '6592-7866-3024-5314', 'S', NULL, NULL, NULL, NULL);
INSERT INTO cuenta_registrada VALUES (4, 1, '1475-4858-1691-5789', 'S', NULL, NULL, NULL, NULL);
INSERT INTO cuenta_registrada VALUES (5, 1, '3992-3343-8699-1754', 'S', NULL, NULL, NULL, NULL);
INSERT INTO cuenta_registrada VALUES (6, 1, '9065-8351-4489-8687', 'S', NULL, NULL, NULL, NULL);
INSERT INTO cuenta_registrada VALUES (7, 1, '2928-4331-8647-0560', 'S', NULL, NULL, NULL, NULL);
INSERT INTO cuenta_registrada VALUES (8, 1, '7173-6253-2005-9312', 'S', NULL, NULL, NULL, NULL);


--
-- TOC entry 2324 (class 0 OID 0)
-- Dependencies: 190
-- Name: cuenta_registrada_cure_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('cuenta_registrada_cure_id_seq', 8, true);


--
-- TOC entry 2302 (class 0 OID 35321)
-- Dependencies: 202
-- Data for Name: employee_audits; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2325 (class 0 OID 0)
-- Dependencies: 201
-- Name: employee_audits_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employee_audits_id_seq', 1, false);


--
-- TOC entry 2300 (class 0 OID 35313)
-- Dependencies: 200
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 2326 (class 0 OID 0)
-- Dependencies: 199
-- Name: employees_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('employees_id_seq', 1, false);


--
-- TOC entry 2304 (class 0 OID 35368)
-- Dependencies: 205
-- Data for Name: huella; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO huella VALUES (43, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'huella_tmp', '\x17d9b439f0e01223ffc94478aae95c211166c522b9e67ab5b1253eddcebc7999');
INSERT INTO huella VALUES (44, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'employee_audits', '\x7edf323fe56d3150c367614d2ade58ef10d169ca79098565b2f8014e8f620ee4');
INSERT INTO huella VALUES (45, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'employees', '\xe42e4e2b7125db7c947de59d19483dc2f8ede755eedcf4e3651f940f278f8f45');
INSERT INTO huella VALUES (46, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'cliente', '\xb4d50507d0de5a5d385bf9f22edfbdba83a1273696edd899231a7606d9c749d4');
INSERT INTO huella VALUES (47, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'usuario', '\x3e167887f6c84d1ee5c72cac373555cfd87ab7a23450450f965d8ad75725fe3f');
INSERT INTO huella VALUES (48, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'vw_cliente_simple', '\x3f069af678de4d3d1f48619b0030e7085dbd313dd96fc41a752d82abb6ba0973');
INSERT INTO huella VALUES (49, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'cuenta_registrada', '\x11af4aed3ccb54efb91eccafabb91a7e3c3e82118c0cbb75558e08353ce39c3d');
INSERT INTO huella VALUES (50, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'tipo_usuario', '\x395042799b1b77e499d0cf16e46b18cb3093b422fd5e7a865493dd264d51f21e');
INSERT INTO huella VALUES (51, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'tipo_documento', '\x2d97f909ad16bb2b2482ba1906ea7f231cd5cb0bd9fcf81ee4dcfa3fec648ce1');
INSERT INTO huella VALUES (52, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'cuenta', '\x8eeb5ccc88e1b4c3c1eec88e3a6ff2b9d2c00cad6d1a8277590e7d79670ac55a');
INSERT INTO huella VALUES (53, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'huella', '\x214a681c6111c357295bb73ec4d9f9725459c2d83ffc2fabe792359cf1dc8bd6');
INSERT INTO huella VALUES (54, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'transaccion', '\xad22f684ea6738f289f902bee98581a92296fe22294e718bbde5e5f38013d506');
INSERT INTO huella VALUES (55, 'R1', '2019-11-30 08:45:21', 'Tabla/Vista', 'tipo_transaccion', '\x2fe581ffcb8d7b256751c43983562168db8c0402fba56a8c5466a6df30ab7842');
INSERT INTO huella VALUES (56, 'R1', '2019-11-30 08:45:21', 'Funciones/Trigger', 'fc_generarrelease', '\xbfdb968d3097ec03db4cf31ac0f5582cc1fce7ebed28a541ea8c6a1ac37caeec');
INSERT INTO huella VALUES (57, 'R1', '2019-11-30 08:45:21', 'Funciones/Trigger', 'fc_sha256function', '\xa690cf17d280b4926f87878567a42b899f5d35c6738329f0bce3cc7abe088a01');
INSERT INTO huella VALUES (58, 'R1', '2019-11-30 08:45:21', 'Funciones/Trigger', 'fc_sha256sequence', '\xa7ecf123bd1d03f160332af0c30c0acefb09260d7a6530ea716cca5122f28122');
INSERT INTO huella VALUES (59, 'R1', '2019-11-30 08:45:21', 'Funciones/Trigger', 'fc_sha256table', '\x63493050c96f79f1357703eaf77fbe60d628f70406fd24b856257f1bee2e1ca4');
INSERT INTO huella VALUES (60, 'R1', '2019-11-30 08:45:21', 'Funciones/Trigger', 'fc_validarrelease', '\xde353cb38d068484dd4e2ae5fe517f66e2309474175e3432ab3bfbd605fa74bc');
INSERT INTO huella VALUES (61, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'huella_tmp', '\x17d9b439f0e01223ffc94478aae95c211166c522b9e67ab5b1253eddcebc7999');
INSERT INTO huella VALUES (62, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'employee_audits', '\x7edf323fe56d3150c367614d2ade58ef10d169ca79098565b2f8014e8f620ee4');
INSERT INTO huella VALUES (63, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'employees', '\xe42e4e2b7125db7c947de59d19483dc2f8ede755eedcf4e3651f940f278f8f45');
INSERT INTO huella VALUES (64, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'cliente', '\xb4d50507d0de5a5d385bf9f22edfbdba83a1273696edd899231a7606d9c749d4');
INSERT INTO huella VALUES (65, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'usuario', '\x3e167887f6c84d1ee5c72cac373555cfd87ab7a23450450f965d8ad75725fe3f');
INSERT INTO huella VALUES (66, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'vw_cliente_simple', '\x3f069af678de4d3d1f48619b0030e7085dbd313dd96fc41a752d82abb6ba0973');
INSERT INTO huella VALUES (67, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'cuenta_registrada', '\x11af4aed3ccb54efb91eccafabb91a7e3c3e82118c0cbb75558e08353ce39c3d');
INSERT INTO huella VALUES (68, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'tipo_usuario', '\x395042799b1b77e499d0cf16e46b18cb3093b422fd5e7a865493dd264d51f21e');
INSERT INTO huella VALUES (69, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'tipo_documento', '\x2d97f909ad16bb2b2482ba1906ea7f231cd5cb0bd9fcf81ee4dcfa3fec648ce1');
INSERT INTO huella VALUES (70, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'cuenta', '\x8eeb5ccc88e1b4c3c1eec88e3a6ff2b9d2c00cad6d1a8277590e7d79670ac55a');
INSERT INTO huella VALUES (71, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'huella', '\x214a681c6111c357295bb73ec4d9f9725459c2d83ffc2fabe792359cf1dc8bd6');
INSERT INTO huella VALUES (72, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'transaccion', '\xad22f684ea6738f289f902bee98581a92296fe22294e718bbde5e5f38013d506');
INSERT INTO huella VALUES (73, 'R3', '2019-11-30 08:48:45', 'Tabla/Vista', 'tipo_transaccion', '\x2fe581ffcb8d7b256751c43983562168db8c0402fba56a8c5466a6df30ab7842');
INSERT INTO huella VALUES (74, 'R3', '2019-11-30 08:48:45', 'Funciones/Trigger', 'fc_generarrelease', '\xbfdb968d3097ec03db4cf31ac0f5582cc1fce7ebed28a541ea8c6a1ac37caeec');
INSERT INTO huella VALUES (75, 'R3', '2019-11-30 08:48:45', 'Funciones/Trigger', 'fc_sha256function', '\xa690cf17d280b4926f87878567a42b899f5d35c6738329f0bce3cc7abe088a01');
INSERT INTO huella VALUES (76, 'R3', '2019-11-30 08:48:45', 'Funciones/Trigger', 'fc_sha256sequence', '\xa7ecf123bd1d03f160332af0c30c0acefb09260d7a6530ea716cca5122f28122');
INSERT INTO huella VALUES (77, 'R3', '2019-11-30 08:48:45', 'Funciones/Trigger', 'fc_sha256table', '\x63493050c96f79f1357703eaf77fbe60d628f70406fd24b856257f1bee2e1ca4');
INSERT INTO huella VALUES (78, 'R3', '2019-11-30 08:48:45', 'Funciones/Trigger', 'fc_validarrelease', '\xde353cb38d068484dd4e2ae5fe517f66e2309474175e3432ab3bfbd605fa74bc');
INSERT INTO huella VALUES (79, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'huella_tmp', '\x17d9b439f0e01223ffc94478aae95c211166c522b9e67ab5b1253eddcebc7999');
INSERT INTO huella VALUES (80, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'employee_audits', '\x7edf323fe56d3150c367614d2ade58ef10d169ca79098565b2f8014e8f620ee4');
INSERT INTO huella VALUES (81, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'employees', '\xe42e4e2b7125db7c947de59d19483dc2f8ede755eedcf4e3651f940f278f8f45');
INSERT INTO huella VALUES (82, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'cliente', '\xb4d50507d0de5a5d385bf9f22edfbdba83a1273696edd899231a7606d9c749d4');
INSERT INTO huella VALUES (83, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'usuario', '\x3e167887f6c84d1ee5c72cac373555cfd87ab7a23450450f965d8ad75725fe3f');
INSERT INTO huella VALUES (84, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'vw_cliente_simple', '\x3f069af678de4d3d1f48619b0030e7085dbd313dd96fc41a752d82abb6ba0973');
INSERT INTO huella VALUES (85, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'cuenta_registrada', '\x11af4aed3ccb54efb91eccafabb91a7e3c3e82118c0cbb75558e08353ce39c3d');
INSERT INTO huella VALUES (86, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'tipo_usuario', '\x395042799b1b77e499d0cf16e46b18cb3093b422fd5e7a865493dd264d51f21e');
INSERT INTO huella VALUES (87, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'tipo_documento', '\x2d97f909ad16bb2b2482ba1906ea7f231cd5cb0bd9fcf81ee4dcfa3fec648ce1');
INSERT INTO huella VALUES (88, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'cuenta', '\x8eeb5ccc88e1b4c3c1eec88e3a6ff2b9d2c00cad6d1a8277590e7d79670ac55a');
INSERT INTO huella VALUES (89, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'huella', '\x214a681c6111c357295bb73ec4d9f9725459c2d83ffc2fabe792359cf1dc8bd6');
INSERT INTO huella VALUES (90, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'transaccion', '\xad22f684ea6738f289f902bee98581a92296fe22294e718bbde5e5f38013d506');
INSERT INTO huella VALUES (91, 'R4', '2019-11-30 08:48:56', 'Tabla/Vista', 'tipo_transaccion', '\x2fe581ffcb8d7b256751c43983562168db8c0402fba56a8c5466a6df30ab7842');
INSERT INTO huella VALUES (92, 'R4', '2019-11-30 08:48:56', 'Funciones/Trigger', 'fc_generarrelease', '\xbfdb968d3097ec03db4cf31ac0f5582cc1fce7ebed28a541ea8c6a1ac37caeec');
INSERT INTO huella VALUES (93, 'R4', '2019-11-30 08:48:56', 'Funciones/Trigger', 'fc_sha256function', '\xa690cf17d280b4926f87878567a42b899f5d35c6738329f0bce3cc7abe088a01');
INSERT INTO huella VALUES (94, 'R4', '2019-11-30 08:48:56', 'Funciones/Trigger', 'fc_sha256sequence', '\xa7ecf123bd1d03f160332af0c30c0acefb09260d7a6530ea716cca5122f28122');
INSERT INTO huella VALUES (95, 'R4', '2019-11-30 08:48:56', 'Funciones/Trigger', 'fc_sha256table', '\x63493050c96f79f1357703eaf77fbe60d628f70406fd24b856257f1bee2e1ca4');
INSERT INTO huella VALUES (96, 'R4', '2019-11-30 08:48:56', 'Funciones/Trigger', 'fc_validarrelease', '\xde353cb38d068484dd4e2ae5fe517f66e2309474175e3432ab3bfbd605fa74bc');
INSERT INTO huella VALUES (97, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'huella_tmp', '\x17d9b439f0e01223ffc94478aae95c211166c522b9e67ab5b1253eddcebc7999');
INSERT INTO huella VALUES (98, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'employee_audits', '\x7edf323fe56d3150c367614d2ade58ef10d169ca79098565b2f8014e8f620ee4');
INSERT INTO huella VALUES (99, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'employees', '\xe42e4e2b7125db7c947de59d19483dc2f8ede755eedcf4e3651f940f278f8f45');
INSERT INTO huella VALUES (100, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'cliente', '\xb4d50507d0de5a5d385bf9f22edfbdba83a1273696edd899231a7606d9c749d4');
INSERT INTO huella VALUES (101, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'usuario', '\x3e167887f6c84d1ee5c72cac373555cfd87ab7a23450450f965d8ad75725fe3f');
INSERT INTO huella VALUES (102, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'vw_cliente_simple', '\x3f069af678de4d3d1f48619b0030e7085dbd313dd96fc41a752d82abb6ba0973');
INSERT INTO huella VALUES (103, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'cuenta_registrada', '\x11af4aed3ccb54efb91eccafabb91a7e3c3e82118c0cbb75558e08353ce39c3d');
INSERT INTO huella VALUES (104, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'tipo_usuario', '\x395042799b1b77e499d0cf16e46b18cb3093b422fd5e7a865493dd264d51f21e');
INSERT INTO huella VALUES (105, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'tipo_documento', '\x2d97f909ad16bb2b2482ba1906ea7f231cd5cb0bd9fcf81ee4dcfa3fec648ce1');
INSERT INTO huella VALUES (106, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'cuenta', '\xa85f42b68c43bfcb98e632b6b89f3c92c421ceeea9130a635407af71d67d1a3e');
INSERT INTO huella VALUES (107, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'huella', '\x214a681c6111c357295bb73ec4d9f9725459c2d83ffc2fabe792359cf1dc8bd6');
INSERT INTO huella VALUES (108, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'transaccion', '\xad22f684ea6738f289f902bee98581a92296fe22294e718bbde5e5f38013d506');
INSERT INTO huella VALUES (109, 'R5', '2019-11-30 08:49:37', 'Tabla/Vista', 'tipo_transaccion', '\x2fe581ffcb8d7b256751c43983562168db8c0402fba56a8c5466a6df30ab7842');
INSERT INTO huella VALUES (110, 'R5', '2019-11-30 08:49:37', 'Funciones/Trigger', 'fc_generarrelease', '\xbfdb968d3097ec03db4cf31ac0f5582cc1fce7ebed28a541ea8c6a1ac37caeec');
INSERT INTO huella VALUES (111, 'R5', '2019-11-30 08:49:37', 'Funciones/Trigger', 'fc_sha256function', '\xa690cf17d280b4926f87878567a42b899f5d35c6738329f0bce3cc7abe088a01');
INSERT INTO huella VALUES (112, 'R5', '2019-11-30 08:49:37', 'Funciones/Trigger', 'fc_sha256sequence', '\xa7ecf123bd1d03f160332af0c30c0acefb09260d7a6530ea716cca5122f28122');
INSERT INTO huella VALUES (113, 'R5', '2019-11-30 08:49:37', 'Funciones/Trigger', 'fc_sha256table', '\x63493050c96f79f1357703eaf77fbe60d628f70406fd24b856257f1bee2e1ca4');
INSERT INTO huella VALUES (114, 'R5', '2019-11-30 08:49:37', 'Funciones/Trigger', 'fc_validarrelease', '\xde353cb38d068484dd4e2ae5fe517f66e2309474175e3432ab3bfbd605fa74bc');
INSERT INTO huella VALUES (115, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'huella_tmp', '\x17d9b439f0e01223ffc94478aae95c211166c522b9e67ab5b1253eddcebc7999');
INSERT INTO huella VALUES (116, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'employee_audits', '\x7edf323fe56d3150c367614d2ade58ef10d169ca79098565b2f8014e8f620ee4');
INSERT INTO huella VALUES (117, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'employees', '\xe42e4e2b7125db7c947de59d19483dc2f8ede755eedcf4e3651f940f278f8f45');
INSERT INTO huella VALUES (118, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'cliente', '\xb4d50507d0de5a5d385bf9f22edfbdba83a1273696edd899231a7606d9c749d4');
INSERT INTO huella VALUES (119, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'usuario', '\x3e167887f6c84d1ee5c72cac373555cfd87ab7a23450450f965d8ad75725fe3f');
INSERT INTO huella VALUES (120, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'vw_cliente_simple', '\x3f069af678de4d3d1f48619b0030e7085dbd313dd96fc41a752d82abb6ba0973');
INSERT INTO huella VALUES (121, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'cuenta_registrada', '\x11af4aed3ccb54efb91eccafabb91a7e3c3e82118c0cbb75558e08353ce39c3d');
INSERT INTO huella VALUES (122, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'tipo_usuario', '\x395042799b1b77e499d0cf16e46b18cb3093b422fd5e7a865493dd264d51f21e');
INSERT INTO huella VALUES (123, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'tipo_documento', '\x2d97f909ad16bb2b2482ba1906ea7f231cd5cb0bd9fcf81ee4dcfa3fec648ce1');
INSERT INTO huella VALUES (124, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'cuenta', '\xa85f42b68c43bfcb98e632b6b89f3c92c421ceeea9130a635407af71d67d1a3e');
INSERT INTO huella VALUES (125, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'huella', '\x214a681c6111c357295bb73ec4d9f9725459c2d83ffc2fabe792359cf1dc8bd6');
INSERT INTO huella VALUES (126, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'transaccion', '\xad22f684ea6738f289f902bee98581a92296fe22294e718bbde5e5f38013d506');
INSERT INTO huella VALUES (127, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'tipo_transaccion', '\x2fe581ffcb8d7b256751c43983562168db8c0402fba56a8c5466a6df30ab7842');
INSERT INTO huella VALUES (128, 'Final', '2019-11-30 08:52:12', 'Funciones/Trigger', 'fc_generarrelease', '\xbfdb968d3097ec03db4cf31ac0f5582cc1fce7ebed28a541ea8c6a1ac37caeec');
INSERT INTO huella VALUES (129, 'Final', '2019-11-30 08:52:12', 'Funciones/Trigger', 'fc_sha256function', '\xa690cf17d280b4926f87878567a42b899f5d35c6738329f0bce3cc7abe088a01');
INSERT INTO huella VALUES (130, 'Final', '2019-11-30 08:52:12', 'Funciones/Trigger', 'fc_sha256sequence', '\xa7ecf123bd1d03f160332af0c30c0acefb09260d7a6530ea716cca5122f28122');
INSERT INTO huella VALUES (131, 'Final', '2019-11-30 08:52:12', 'Funciones/Trigger', 'fc_sha256table', '\x63493050c96f79f1357703eaf77fbe60d628f70406fd24b856257f1bee2e1ca4');
INSERT INTO huella VALUES (132, 'Final', '2019-11-30 08:52:12', 'Funciones/Trigger', 'fc_validarrelease', '\xde353cb38d068484dd4e2ae5fe517f66e2309474175e3432ab3bfbd605fa74bc');


--
-- TOC entry 2327 (class 0 OID 0)
-- Dependencies: 204
-- Name: huella_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('huella_id_seq', 132, true);


--
-- TOC entry 2306 (class 0 OID 35387)
-- Dependencies: 207
-- Data for Name: huella_tmp; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO huella_tmp VALUES (475, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'huella_tmp', '\x17d9b439f0e01223ffc94478aae95c211166c522b9e67ab5b1253eddcebc7999', '\x17d9b439f0e01223ffc94478aae95c211166c522b9e67ab5b1253eddcebc7999');
INSERT INTO huella_tmp VALUES (476, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'employee_audits', '\x7edf323fe56d3150c367614d2ade58ef10d169ca79098565b2f8014e8f620ee4', '\x7edf323fe56d3150c367614d2ade58ef10d169ca79098565b2f8014e8f620ee4');
INSERT INTO huella_tmp VALUES (477, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'employees', '\xe42e4e2b7125db7c947de59d19483dc2f8ede755eedcf4e3651f940f278f8f45', '\xe42e4e2b7125db7c947de59d19483dc2f8ede755eedcf4e3651f940f278f8f45');
INSERT INTO huella_tmp VALUES (478, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'cliente', '\xb4d50507d0de5a5d385bf9f22edfbdba83a1273696edd899231a7606d9c749d4', '\xcb19fc56e4c0294f13dff8b4bccc8661e243c1e37202823a4c6f3ede328eb60c');
INSERT INTO huella_tmp VALUES (479, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'usuario', '\x3e167887f6c84d1ee5c72cac373555cfd87ab7a23450450f965d8ad75725fe3f', '\x3e167887f6c84d1ee5c72cac373555cfd87ab7a23450450f965d8ad75725fe3f');
INSERT INTO huella_tmp VALUES (480, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'vw_cliente_simple', '\x3f069af678de4d3d1f48619b0030e7085dbd313dd96fc41a752d82abb6ba0973', '\x3f069af678de4d3d1f48619b0030e7085dbd313dd96fc41a752d82abb6ba0973');
INSERT INTO huella_tmp VALUES (481, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'cuenta_registrada', '\x11af4aed3ccb54efb91eccafabb91a7e3c3e82118c0cbb75558e08353ce39c3d', '\x11af4aed3ccb54efb91eccafabb91a7e3c3e82118c0cbb75558e08353ce39c3d');
INSERT INTO huella_tmp VALUES (482, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'tipo_usuario', '\x395042799b1b77e499d0cf16e46b18cb3093b422fd5e7a865493dd264d51f21e', '\x395042799b1b77e499d0cf16e46b18cb3093b422fd5e7a865493dd264d51f21e');
INSERT INTO huella_tmp VALUES (483, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'tipo_documento', '\x2d97f909ad16bb2b2482ba1906ea7f231cd5cb0bd9fcf81ee4dcfa3fec648ce1', '\x2d97f909ad16bb2b2482ba1906ea7f231cd5cb0bd9fcf81ee4dcfa3fec648ce1');
INSERT INTO huella_tmp VALUES (484, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'cuenta', '\xa85f42b68c43bfcb98e632b6b89f3c92c421ceeea9130a635407af71d67d1a3e', '\xa85f42b68c43bfcb98e632b6b89f3c92c421ceeea9130a635407af71d67d1a3e');
INSERT INTO huella_tmp VALUES (485, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'huella', '\x214a681c6111c357295bb73ec4d9f9725459c2d83ffc2fabe792359cf1dc8bd6', '\x214a681c6111c357295bb73ec4d9f9725459c2d83ffc2fabe792359cf1dc8bd6');
INSERT INTO huella_tmp VALUES (486, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'transaccion', '\xad22f684ea6738f289f902bee98581a92296fe22294e718bbde5e5f38013d506', '\xad22f684ea6738f289f902bee98581a92296fe22294e718bbde5e5f38013d506');
INSERT INTO huella_tmp VALUES (487, 'Final', '2019-11-30 08:52:12', 'Tabla/Vista', 'tipo_transaccion', '\x2fe581ffcb8d7b256751c43983562168db8c0402fba56a8c5466a6df30ab7842', '\x2fe581ffcb8d7b256751c43983562168db8c0402fba56a8c5466a6df30ab7842');
INSERT INTO huella_tmp VALUES (488, 'Final', '2019-11-30 08:52:12', 'Funciones/Trigger', 'fc_generarrelease', '\xbfdb968d3097ec03db4cf31ac0f5582cc1fce7ebed28a541ea8c6a1ac37caeec', '\xbfdb968d3097ec03db4cf31ac0f5582cc1fce7ebed28a541ea8c6a1ac37caeec');
INSERT INTO huella_tmp VALUES (489, 'Final', '2019-11-30 08:52:12', 'Funciones/Trigger', 'fc_sha256function', '\xa690cf17d280b4926f87878567a42b899f5d35c6738329f0bce3cc7abe088a01', '\xa690cf17d280b4926f87878567a42b899f5d35c6738329f0bce3cc7abe088a01');
INSERT INTO huella_tmp VALUES (490, 'Final', '2019-11-30 08:52:12', 'Funciones/Trigger', 'fc_sha256sequence', '\xa7ecf123bd1d03f160332af0c30c0acefb09260d7a6530ea716cca5122f28122', '\xa7ecf123bd1d03f160332af0c30c0acefb09260d7a6530ea716cca5122f28122');
INSERT INTO huella_tmp VALUES (491, 'Final', '2019-11-30 08:52:12', 'Funciones/Trigger', 'fc_sha256table', '\x63493050c96f79f1357703eaf77fbe60d628f70406fd24b856257f1bee2e1ca4', '\x63493050c96f79f1357703eaf77fbe60d628f70406fd24b856257f1bee2e1ca4');
INSERT INTO huella_tmp VALUES (492, 'Final', '2019-11-30 08:52:12', 'Funciones/Trigger', 'fc_validarrelease', '\xde353cb38d068484dd4e2ae5fe517f66e2309474175e3432ab3bfbd605fa74bc', '\xde353cb38d068484dd4e2ae5fe517f66e2309474175e3432ab3bfbd605fa74bc');


--
-- TOC entry 2328 (class 0 OID 0)
-- Dependencies: 206
-- Name: huella_tmp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('huella_tmp_id_seq', 492, true);


--
-- TOC entry 2288 (class 0 OID 35133)
-- Dependencies: 188
-- Data for Name: tipo_documento; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tipo_documento VALUES (1, 'CEDULA', 'S', NULL, NULL, NULL, NULL);
INSERT INTO tipo_documento VALUES (2, 'TARJETA DE IDENTIDAD', 'S', NULL, NULL, NULL, NULL);
INSERT INTO tipo_documento VALUES (3, 'CEDULA DE EXTRANJERIA', 'S', NULL, NULL, NULL, NULL);


--
-- TOC entry 2329 (class 0 OID 0)
-- Dependencies: 187
-- Name: tipo_documento_tdoc_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tipo_documento_tdoc_id_seq', 3, true);


--
-- TOC entry 2298 (class 0 OID 35200)
-- Dependencies: 198
-- Data for Name: tipo_transaccion; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tipo_transaccion VALUES (1, 'RETIRO', 'S', NULL, NULL, NULL, NULL);
INSERT INTO tipo_transaccion VALUES (2, 'CONSIGNACION', 'S', NULL, NULL, NULL, NULL);
INSERT INTO tipo_transaccion VALUES (3, 'TRANSFERENCIA', 'S', NULL, NULL, NULL, NULL);


--
-- TOC entry 2330 (class 0 OID 0)
-- Dependencies: 197
-- Name: tipo_transaccion_titr_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tipo_transaccion_titr_id_seq', 3, true);


--
-- TOC entry 2296 (class 0 OID 35189)
-- Dependencies: 196
-- Data for Name: tipo_usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO tipo_usuario VALUES (1, 'CAJERO', 'S', NULL, NULL, NULL, NULL);
INSERT INTO tipo_usuario VALUES (2, 'ASESOR COMERCIAL', 'S', NULL, NULL, NULL, NULL);
INSERT INTO tipo_usuario VALUES (3, 'ADMINISTRADOR', 'S', NULL, NULL, NULL, NULL);


--
-- TOC entry 2331 (class 0 OID 0)
-- Dependencies: 195
-- Name: tipo_usuario_tius_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('tipo_usuario_tius_id_seq', 3, true);


--
-- TOC entry 2293 (class 0 OID 35166)
-- Dependencies: 193
-- Data for Name: transaccion; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO transaccion VALUES (1, '4640-0341-9387-5781', 160894372.000000, '2017-02-12 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2, '1630-2511-2937-7299', 333856193.000000, '2016-12-02 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (3, '6592-7866-3024-5314', 211804798.000000, '2017-02-13 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (4, '1475-4858-1691-5789', 158919671.000000, '2017-02-14 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (5, '3992-3343-8699-1754', 407161027.000000, '2016-12-11 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (6, '9065-8351-4489-8687', 205336049.000000, '2016-08-09 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (7, '2928-4331-8647-0560', 184082336.000000, '2017-06-25 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (8, '7173-6253-2005-9312', 299763143.000000, '2017-02-10 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (9, '6939-8463-2899-6921', 366864879.000000, '2017-02-05 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (10, '1215-0877-5497-4162', 400650449.000000, '2016-12-07 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (11, '2632-3183-7851-1820', 156669607.000000, '2017-03-13 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (12, '9935-9879-2260-2925', 352965554.000000, '2017-02-05 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (13, '9964-7808-5543-3283', 399224058.000000, '2017-07-04 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (14, '1029-9774-2970-1730', 300766748.000000, '2016-09-02 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (15, '4542-3132-7580-5698', 410264589.000000, '2016-11-02 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (16, '5476-9906-2825-9952', 381999744.000000, '2017-01-18 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (17, '3730-3787-8629-3917', 231885360.000000, '2017-05-11 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (18, '1178-7900-5881-6552', 348778743.000000, '2017-03-08 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (19, '5318-9901-9863-4382', 160571877.000000, '2017-03-22 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (20, '0350-1117-8856-7980', 384037433.000000, '2017-07-07 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (21, '6583-2282-3212-0467', 150814303.000000, '2017-01-14 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (22, '1541-4277-0660-4459', 424055052.000000, '2016-08-03 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (23, '9590-2625-2150-7258', 172401252.000000, '2017-01-02 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (24, '0636-0754-0405-3314', 273011802.000000, '2017-07-17 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (25, '2363-7005-2893-4182', 323444850.000000, '2016-11-25 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (26, '1683-9992-4718-7113', 210000148.000000, '2017-05-24 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (27, '5095-6341-6973-5274', 341136129.000000, '2016-08-19 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (28, '9181-1189-4069-8436', 287499492.000000, '2017-03-13 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (29, '1866-9428-1104-6886', 398017171.000000, '2017-06-15 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (30, '8278-7710-7311-4788', 251937656.000000, '2016-09-24 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (31, '4064-9491-1791-9866', 160427669.000000, '2016-08-02 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (32, '0117-2729-2666-4999', 353960019.000000, '2017-04-07 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (33, '9455-7519-9184-1316', 382402266.000000, '2016-11-21 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (34, '4489-2174-0669-7685', 356621166.000000, '2017-02-04 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (35, '6760-5797-6026-8236', 204234991.000000, '2016-11-08 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (36, '0475-0347-5867-3706', 379686774.000000, '2017-06-20 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (37, '1164-3535-1779-9752', 390859207.000000, '2017-04-18 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (38, '8918-2649-5470-5706', 283041341.000000, '2017-04-20 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (39, '6499-7973-8172-6081', 442219805.000000, '2016-09-30 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (40, '8466-6269-4466-4874', 361896506.000000, '2017-06-01 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (41, '9999-8370-6668-7190', 234360113.000000, '2017-07-27 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (42, '7116-7842-3370-2242', 427846400.000000, '2016-12-12 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (43, '7761-2171-6893-8685', 281887759.000000, '2017-02-27 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (44, '7486-5639-1437-3118', 213815625.000000, '2016-09-17 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (45, '3407-5270-2479-7393', 170219769.000000, '2016-09-30 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (46, '2079-4572-9595-5154', 184279538.000000, '2017-02-08 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (47, '6758-7942-1548-0121', 306571926.000000, '2017-01-03 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (48, '9591-3296-4863-4542', 190028918.000000, '2016-09-12 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (49, '1189-7024-1496-1936', 313033468.000000, '2016-12-19 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (50, '2632-8850-8767-6806', 170529889.000000, '2016-09-24 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (51, '9505-0277-8346-3969', 375725643.000000, '2017-01-12 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (52, '2139-8397-7084-4093', 407675038.000000, '2017-07-11 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (53, '8496-8115-5596-9722', 282616164.000000, '2017-06-01 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (54, '1078-8795-8240-6760', 187345681.000000, '2017-01-17 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (55, '6447-3132-2386-3059', 150595229.000000, '2016-12-26 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (56, '4868-7136-8392-3176', 423388188.000000, '2016-12-05 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (57, '3803-6035-3793-4001', 398001775.000000, '2016-09-20 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (58, '4491-5667-1554-9630', 378052213.000000, '2017-05-05 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (59, '0268-5280-7709-0786', 421664213.000000, '2017-06-03 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (60, '8949-3946-3107-0179', 371091156.000000, '2016-11-15 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (61, '6121-8028-2625-4222', 310848040.000000, '2017-07-27 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (62, '8745-0201-1661-2523', 389976721.000000, '2016-08-18 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (63, '4935-1821-8202-2968', 359581416.000000, '2017-05-02 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (64, '6746-5524-6238-5271', 345518682.000000, '2016-09-07 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (65, '3526-8802-4949-4634', 180322079.000000, '2017-06-28 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (66, '7664-2611-7081-6632', 392493887.000000, '2017-03-28 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (67, '6541-5717-5729-7113', 436600546.000000, '2016-10-08 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (68, '3372-1461-3357-0143', 251633351.000000, '2016-08-04 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (69, '9689-1520-0552-2257', 408446571.000000, '2017-02-05 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (70, '2802-2131-5201-0271', 214734569.000000, '2017-08-06 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (71, '5206-5934-1915-3021', 363967136.000000, '2016-12-24 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (72, '6491-2184-3317-1931', 242542531.000000, '2016-09-18 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (73, '6635-4746-9618-9316', 237624331.000000, '2016-12-01 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (74, '3368-0816-3360-9187', 197878717.000000, '2017-04-20 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (75, '5428-5398-1935-2463', 325641974.000000, '2017-01-02 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (76, '2650-5157-3672-6578', 324186377.000000, '2017-05-06 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (77, '4192-8466-3559-0834', 246526241.000000, '2017-02-25 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (78, '8203-9351-1310-1235', 245418643.000000, '2016-10-18 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (79, '9400-6128-0621-5409', 264488100.000000, '2016-10-27 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (80, '4119-6950-3561-4992', 407487802.000000, '2017-02-04 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (81, '0346-9608-7387-6327', 430118488.000000, '2016-09-01 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (82, '5622-1722-7571-8255', 407325392.000000, '2016-09-13 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (83, '8959-5852-1379-0192', 361193591.000000, '2016-11-04 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (84, '6557-7799-9961-8218', 281190434.000000, '2016-09-25 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (85, '0514-4787-8982-4300', 200273726.000000, '2017-07-23 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (86, '0140-4923-2389-0727', 350422760.000000, '2017-02-26 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (87, '3780-0383-1667-6535', 383939587.000000, '2017-02-22 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (88, '1986-8035-6874-7565', 313240060.000000, '2017-01-07 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (89, '0820-4587-6824-7985', 292999998.000000, '2016-12-04 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (90, '4452-2795-2853-9523', 351684141.000000, '2016-09-09 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (91, '7401-6719-2903-4065', 265828019.000000, '2017-05-28 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (92, '9363-1099-8826-5566', 371799160.000000, '2017-07-24 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (93, '1123-4560-6785-9543', 289847221.000000, '2016-09-12 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (94, '5551-1019-1170-6548', 318362548.000000, '2017-06-09 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (95, '6313-3080-5678-3858', 316741175.000000, '2017-02-20 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (96, '4710-8990-0069-3222', 157934404.000000, '2016-10-20 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (97, '1363-2180-8920-1867', 210285817.000000, '2017-08-04 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (98, '0181-2541-5255-2584', 235745238.000000, '2017-02-06 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (99, '7665-4361-2051-0234', 157483953.000000, '2017-07-13 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (100, '3671-1051-5487-3782', 410730671.000000, '2016-10-19 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (101, '6424-8071-9108-4502', 294004936.000000, '2016-10-02 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (102, '7820-4469-0702-7629', 215613090.000000, '2017-02-16 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (103, '8208-5994-1776-8085', 246152088.000000, '2016-11-20 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (104, '4981-4577-3614-8588', 285243893.000000, '2016-09-02 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (105, '7328-1152-9776-2856', 151055252.000000, '2017-01-13 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (106, '5477-1421-8772-8324', 399546665.000000, '2016-08-29 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (107, '9319-6402-6367-9643', 205401526.000000, '2017-02-06 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (108, '0692-8676-7680-5833', 251138774.000000, '2017-01-16 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (109, '6853-1210-7083-5530', 228400696.000000, '2016-11-13 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (110, '2107-2630-0013-7168', 419821671.000000, '2017-05-05 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (111, '2530-4884-4726-8684', 442600936.000000, '2017-04-29 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (112, '9153-0285-9063-5908', 321420223.000000, '2017-06-07 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (113, '0074-8367-8071-1220', 256721962.000000, '2017-01-17 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (114, '0081-7911-8197-5581', 284001685.000000, '2016-11-21 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (115, '2893-6865-7692-8052', 320176241.000000, '2017-05-26 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (116, '8730-6745-7677-0461', 371265849.000000, '2017-05-04 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (117, '1405-4442-6573-5897', 448282766.000000, '2017-03-09 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (118, '1648-0781-3078-1877', 169380703.000000, '2016-09-16 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (119, '8309-1029-1985-4355', 381874164.000000, '2016-09-16 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (120, '2221-0754-3973-1051', 181565414.000000, '2017-01-02 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (121, '4785-7858-5902-0580', 217455491.000000, '2017-06-04 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (122, '9452-0825-2091-3906', 435447942.000000, '2017-04-24 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (123, '7790-6384-6955-0766', 233514480.000000, '2016-10-26 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (124, '2329-7925-9726-5030', 275125753.000000, '2016-11-02 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (125, '6642-6674-6250-1202', 286537782.000000, '2016-10-18 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (126, '3925-5240-3610-2141', 162685955.000000, '2017-01-09 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (127, '6415-4192-3179-9426', 227019467.000000, '2017-07-25 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (128, '5952-2699-9699-3113', 341881422.000000, '2017-07-04 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (129, '0841-2249-8886-5338', 337632248.000000, '2016-11-12 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (130, '3304-1266-4460-0809', 151107485.000000, '2016-09-08 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (131, '7591-2485-8429-7497', 257155756.000000, '2016-10-23 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (132, '7872-2526-6619-2504', 382470082.000000, '2016-10-31 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (133, '8208-5565-5813-1453', 370776503.000000, '2016-08-21 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (134, '6761-5503-3356-1971', 350628934.000000, '2016-10-23 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (135, '9446-5312-0194-9512', 300637842.000000, '2017-04-14 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (136, '4593-9532-3041-7011', 387611695.000000, '2016-08-07 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (137, '1373-6024-9204-8582', 183363230.000000, '2016-12-23 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (138, '9564-8786-5763-0311', 343523622.000000, '2016-12-03 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (139, '6889-0041-6232-5724', 400893390.000000, '2016-10-13 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (140, '4377-0106-3176-8044', 232690276.000000, '2017-07-27 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (141, '0093-0717-7855-8621', 197424739.000000, '2016-08-09 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (142, '5498-8953-4099-5133', 421405531.000000, '2017-02-22 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (143, '4159-0519-3146-3812', 163499972.000000, '2017-04-27 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (144, '2177-9204-5855-2340', 374914277.000000, '2017-07-02 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (145, '4408-7236-9916-1891', 439440682.000000, '2016-09-29 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (146, '0822-7068-9243-8891', 330382720.000000, '2016-11-16 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (147, '1780-2902-1963-8625', 343161606.000000, '2017-03-14 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (148, '9704-9929-7178-8103', 390199364.000000, '2017-05-24 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (149, '1778-8428-8990-5968', 152882409.000000, '2017-06-11 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (150, '0177-7899-6206-8106', 373593999.000000, '2017-04-11 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (151, '9899-9870-2438-3478', 256966634.000000, '2017-05-03 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (152, '4170-9568-1904-9980', 381460969.000000, '2017-06-24 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (153, '9827-9591-6662-0112', 426549209.000000, '2017-06-30 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (154, '9409-0563-8504-7287', 390052715.000000, '2016-09-05 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (155, '9811-1722-5045-0670', 233643541.000000, '2016-11-02 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (156, '9350-0086-1238-0376', 293720726.000000, '2017-06-06 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (157, '3605-7164-4531-3983', 182462838.000000, '2017-02-08 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (158, '2387-4116-3699-0044', 204867062.000000, '2016-10-22 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (159, '4327-3699-3991-5248', 417758296.000000, '2017-01-05 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (160, '8057-8052-0967-7029', 424058767.000000, '2016-10-02 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (161, '2125-2796-8386-1777', 364239952.000000, '2017-07-15 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (162, '7111-5132-7995-5089', 186653475.000000, '2016-11-15 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (163, '4305-2519-0729-1255', 422998689.000000, '2016-08-27 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (164, '2819-7576-2967-7617', 353672552.000000, '2017-03-04 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (165, '7600-5534-7912-7650', 339231898.000000, '2017-01-10 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (166, '0031-0825-4207-7451', 422532083.000000, '2017-04-26 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (167, '9494-1375-9599-2451', 291472803.000000, '2017-02-09 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (168, '7785-2013-9754-1083', 290546529.000000, '2017-03-25 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (169, '6690-3842-6103-9519', 176379536.000000, '2017-07-13 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (170, '2639-9433-6813-5967', 428028705.000000, '2017-03-17 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (171, '6646-0588-6217-9747', 340528053.000000, '2017-05-12 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (172, '6549-6805-4081-8635', 288762073.000000, '2016-12-25 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (173, '8004-0166-8784-4683', 193133869.000000, '2017-02-10 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (174, '8881-4291-1393-9206', 360103950.000000, '2016-08-16 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (175, '1628-4469-4254-4255', 328345618.000000, '2017-06-15 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (176, '8552-0405-6197-9901', 316305927.000000, '2016-12-13 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (177, '9883-5961-6517-4010', 449541768.000000, '2017-07-31 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (178, '3084-3732-4361-0086', 212430920.000000, '2016-11-21 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (179, '0746-0674-7223-5619', 407085896.000000, '2016-08-06 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (180, '2280-1779-0471-5318', 340262571.000000, '2017-02-24 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (181, '5545-1357-9636-3169', 352551067.000000, '2017-06-17 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (182, '3583-8213-4143-9711', 326060113.000000, '2016-11-04 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (183, '5081-7006-2463-0217', 231911274.000000, '2017-07-13 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (184, '0625-5789-0933-9728', 232485649.000000, '2016-11-25 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (185, '0140-2787-6477-4524', 215232078.000000, '2017-05-19 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (186, '4821-3301-7746-1349', 205810507.000000, '2016-11-10 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (187, '9606-1585-2060-8079', 222108184.000000, '2016-11-06 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (188, '5467-3923-1765-7151', 208630860.000000, '2017-05-01 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (189, '0097-7698-8413-7348', 324657203.000000, '2017-02-01 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (190, '1508-2064-2026-7610', 361615386.000000, '2017-04-21 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (191, '0276-7149-2926-4746', 150947252.000000, '2017-04-03 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (192, '5345-1932-3298-5325', 150737739.000000, '2016-10-17 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (193, '6387-3084-2819-5638', 370247027.000000, '2017-06-15 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (194, '2374-2534-7359-2444', 234690061.000000, '2017-05-31 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (195, '8263-6894-0909-0911', 167731423.000000, '2017-05-26 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (196, '3376-3270-3265-3518', 292840115.000000, '2016-11-16 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (197, '6941-1137-1293-6653', 257546248.000000, '2017-01-31 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (198, '0075-6185-1037-6321', 429144511.000000, '2016-09-13 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (199, '1100-7332-6663-8295', 242789787.000000, '2017-07-29 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (200, '8580-4430-7584-2750', 367392996.000000, '2016-11-07 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (201, '9392-5951-1261-6862', 320992800.000000, '2017-05-08 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (202, '6208-3887-9872-0419', 287979930.000000, '2017-04-01 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (203, '5998-1286-0435-2887', 156646938.000000, '2017-01-26 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (204, '8722-1029-6046-2103', 157745350.000000, '2016-12-26 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (205, '6876-3354-5583-1458', 286249466.000000, '2017-02-23 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (206, '3915-5119-8398-0697', 334601747.000000, '2016-11-04 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (207, '6879-9953-6602-9061', 186493097.000000, '2017-04-04 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (208, '2998-6007-0135-7091', 230389776.000000, '2017-04-14 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (209, '7016-8978-9924-1613', 225572226.000000, '2017-07-18 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (210, '3535-2449-5558-7697', 422801826.000000, '2016-10-30 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (211, '8000-2272-1003-6653', 324360406.000000, '2017-04-30 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (212, '0941-9567-9911-0938', 177756996.000000, '2016-11-21 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (213, '9865-7398-8744-4357', 309190054.000000, '2016-10-05 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (214, '4348-8697-9298-2108', 444280966.000000, '2016-10-28 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (215, '6953-0000-0012-2654', 292307431.000000, '2016-08-18 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (216, '9372-1718-0849-8844', 331923650.000000, '2017-01-16 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (217, '5374-2352-9131-4756', 415036533.000000, '2016-10-29 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (218, '4490-3980-7238-8700', 415606900.000000, '2016-10-09 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (219, '4759-7971-8874-1491', 321025496.000000, '2017-02-26 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (220, '5414-2120-4147-4860', 298442384.000000, '2017-07-24 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (221, '6771-5490-2874-7421', 325254582.000000, '2016-08-22 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (222, '6130-3140-1930-7167', 163307972.000000, '2016-08-05 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (223, '7671-7317-0267-7964', 376799068.000000, '2016-10-08 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (224, '1679-2509-6968-7377', 250472133.000000, '2016-09-16 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (225, '7366-7385-3876-8415', 347061093.000000, '2017-02-09 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (226, '6735-0858-7744-7994', 298538830.000000, '2017-06-26 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (227, '9047-7506-0162-0489', 417421489.000000, '2017-01-18 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (228, '7881-2895-3447-1545', 361200589.000000, '2017-01-29 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (229, '1244-3751-3519-7016', 196379775.000000, '2016-11-06 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (230, '7800-5498-7867-5837', 344610146.000000, '2016-11-15 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (231, '1218-5597-4263-9081', 448340626.000000, '2017-03-14 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (232, '5123-5612-7316-1987', 368534311.000000, '2016-11-19 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (233, '0605-9991-1349-8896', 436855730.000000, '2016-10-23 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (234, '6024-2414-7844-5037', 316183757.000000, '2017-01-29 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (235, '3564-5733-3113-4933', 274411929.000000, '2017-04-25 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (236, '3163-6133-3780-5137', 360736792.000000, '2016-08-29 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (237, '7629-4189-1211-5218', 246725107.000000, '2017-04-14 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (238, '2370-4863-9564-5049', 302465727.000000, '2016-11-16 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (239, '6703-6438-5781-3618', 237927518.000000, '2017-04-06 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (240, '9512-2858-0859-3287', 175879243.000000, '2016-08-20 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (241, '7168-3838-8848-0614', 334411784.000000, '2017-04-23 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (242, '2425-7395-8704-0178', 226760213.000000, '2017-08-02 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (243, '3118-9370-9608-0660', 406366365.000000, '2017-04-28 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (244, '0714-1131-7491-7867', 244371950.000000, '2017-06-20 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (245, '3787-9057-2673-4768', 439784162.000000, '2016-12-19 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (246, '6926-2835-3378-2241', 328539664.000000, '2017-03-28 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (247, '6927-8165-6542-7138', 168031684.000000, '2017-05-16 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (248, '6288-7006-5475-6661', 185134478.000000, '2017-07-05 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (249, '1832-9622-2825-4224', 416246261.000000, '2017-07-01 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (250, '1232-4421-2594-5281', 226914785.000000, '2016-09-25 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (251, '1486-3459-0435-3155', 173264631.000000, '2016-11-06 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (252, '8910-8488-8040-7169', 209176392.000000, '2017-06-20 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (253, '6243-5359-5834-3643', 250165564.000000, '2016-10-14 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (254, '3349-8388-9044-8651', 254209656.000000, '2017-02-03 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (255, '3030-5344-0883-5346', 446848902.000000, '2017-04-28 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (256, '3652-8402-2084-3744', 347169482.000000, '2017-04-16 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (257, '1283-8610-4212-9730', 204950237.000000, '2016-12-24 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (258, '9634-2056-2795-7015', 286664182.000000, '2017-06-05 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (259, '5092-0727-0054-6347', 321352689.000000, '2016-09-20 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (260, '7589-0471-6735-5401', 378021617.000000, '2016-11-08 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (261, '7327-6841-6103-5107', 217641554.000000, '2016-09-12 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (262, '7998-0816-9249-5992', 377711283.000000, '2016-10-28 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (263, '9156-2306-0183-0385', 264192587.000000, '2017-04-03 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (264, '2379-6060-8267-7139', 403344125.000000, '2016-11-24 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (265, '1772-4265-0104-8486', 351864159.000000, '2017-02-12 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (266, '5835-9233-7689-1111', 364297266.000000, '2017-08-05 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (267, '2109-5322-2196-3482', 152153507.000000, '2017-04-24 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (268, '8602-7362-1082-6366', 254142071.000000, '2017-01-12 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (269, '6576-6280-8889-9108', 233332968.000000, '2017-06-29 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (270, '7056-7918-1988-2836', 367003171.000000, '2016-12-16 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (271, '4709-7969-4885-5187', 205469240.000000, '2017-04-15 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (272, '8327-1459-3640-6015', 391486081.000000, '2017-05-30 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (273, '9261-3382-3016-6082', 427721316.000000, '2017-04-17 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (274, '2491-7738-6169-4478', 168967050.000000, '2016-11-18 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (275, '2543-2609-9528-0688', 277425275.000000, '2017-06-29 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (276, '0077-8382-6894-1833', 395526630.000000, '2016-12-18 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (277, '6186-9891-1392-0544', 178289624.000000, '2016-10-28 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (278, '0207-6599-6207-7293', 385496217.000000, '2017-06-03 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (279, '6847-4825-8553-5681', 157069805.000000, '2017-01-28 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (280, '7786-2488-0114-3528', 362453319.000000, '2017-07-11 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (281, '1293-6124-3978-4095', 172591695.000000, '2017-04-15 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (282, '6555-6816-0646-2682', 152636850.000000, '2017-03-02 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (283, '9924-9845-7043-6223', 328210555.000000, '2016-12-07 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (284, '7923-5977-0907-5796', 203865265.000000, '2016-12-10 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (285, '0560-4661-1372-3656', 245324204.000000, '2016-10-12 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (286, '5500-1286-3789-0175', 352616856.000000, '2017-06-02 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (287, '2612-5828-0172-4289', 291932714.000000, '2016-09-03 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (288, '4990-7591-5046-9079', 310496521.000000, '2017-01-18 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (289, '0684-6111-7709-1157', 335863488.000000, '2017-02-23 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (290, '0303-9744-5598-1034', 405448170.000000, '2016-12-07 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (291, '1143-1930-0572-7289', 220045683.000000, '2017-04-17 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (292, '5213-1946-6403-3553', 292073383.000000, '2017-07-23 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (293, '5832-6937-3216-6329', 445689292.000000, '2017-04-03 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (294, '9218-1566-1068-6049', 282500788.000000, '2017-07-23 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (295, '8711-8195-4783-1092', 201216092.000000, '2016-09-02 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (296, '3232-3396-8859-4945', 444867847.000000, '2017-08-05 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (297, '4551-2589-7606-5608', 364858404.000000, '2017-02-24 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (298, '0798-4948-4656-4453', 328988037.000000, '2017-06-07 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (299, '8284-5047-3214-2991', 167410167.000000, '2016-09-11 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (300, '3891-5908-7556-6405', 344384927.000000, '2016-10-26 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (301, '8950-2285-5040-4032', 379293599.000000, '2017-04-07 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (302, '5166-2374-5347-4160', 297809444.000000, '2016-08-15 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (303, '0495-0274-6737-9516', 374295703.000000, '2017-04-05 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (304, '2792-9059-5930-6484', 167222307.000000, '2017-03-19 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (305, '3897-2818-7764-7654', 414765969.000000, '2016-11-11 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (306, '8728-0284-9812-6524', 297343657.000000, '2017-07-27 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (307, '1810-2868-6592-1860', 415798576.000000, '2017-07-20 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (308, '2226-7529-2167-0371', 296176024.000000, '2017-02-07 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (309, '2864-4811-5832-3298', 381800585.000000, '2017-08-01 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (310, '0519-8443-6363-4791', 449390441.000000, '2017-02-17 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (311, '5568-2696-5810-0516', 388958889.000000, '2017-05-23 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (312, '6904-6818-2252-3788', 212023469.000000, '2017-07-06 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (313, '8438-2972-3579-8814', 379018882.000000, '2017-03-21 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (314, '2705-5302-1866-9530', 321433331.000000, '2017-08-07 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (315, '8351-7638-6418-0664', 157085494.000000, '2016-12-17 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (316, '2952-6640-6879-5318', 253311577.000000, '2016-12-15 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (317, '9955-6247-5740-6265', 216387921.000000, '2016-11-30 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (318, '1006-8363-7959-5345', 174076618.000000, '2016-09-12 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (319, '4152-6436-1853-4550', 318701503.000000, '2017-04-01 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (320, '8192-2341-2023-3195', 292568258.000000, '2017-03-26 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (321, '5146-4727-1765-5050', 153529613.000000, '2017-05-28 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (322, '1212-1898-2182-5009', 150916804.000000, '2016-12-24 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (323, '4469-1115-0179-3752', 178262965.000000, '2017-02-12 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (324, '3578-5937-5577-4200', 157494269.000000, '2017-04-03 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (325, '7603-4214-2216-1711', 223890107.000000, '2016-10-16 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (326, '3231-5665-9336-4930', 356547612.000000, '2017-04-19 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (327, '5706-5268-7517-7328', 244313357.000000, '2017-04-19 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (328, '0500-8267-0385-3204', 312620832.000000, '2017-02-11 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (329, '4041-1655-5923-0729', 429209540.000000, '2017-06-08 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (330, '8376-7939-9428-9693', 323387504.000000, '2017-01-11 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (331, '6669-0305-6209-5818', 229848305.000000, '2016-12-10 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (332, '9191-8786-5106-0667', 156556471.000000, '2017-02-16 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (333, '6949-2008-3748-8577', 242240292.000000, '2016-12-15 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (334, '1895-4646-2215-5779', 233799620.000000, '2016-08-15 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (335, '3938-0252-3933-7528', 222407851.000000, '2017-04-22 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (336, '5255-9094-5380-8858', 230620746.000000, '2017-04-05 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (337, '7213-3694-2680-3233', 396316855.000000, '2016-11-02 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (338, '5063-8232-6239-0150', 340768071.000000, '2017-05-03 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (339, '6914-6780-2252-4531', 363191903.000000, '2017-06-21 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (340, '9237-4423-9181-6079', 329732755.000000, '2016-12-04 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (341, '6846-6981-4048-7296', 210652592.000000, '2017-06-20 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (342, '8970-0470-8363-0744', 184321899.000000, '2017-03-05 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (343, '1259-1754-5933-9904', 249053378.000000, '2016-12-04 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (344, '6736-4528-6431-4990', 419989230.000000, '2017-06-19 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (345, '9603-6566-4780-2484', 267971518.000000, '2017-07-31 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (346, '4303-2080-5179-6157', 195735567.000000, '2017-02-25 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (347, '0026-2816-9564-1013', 263438379.000000, '2017-04-12 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (348, '2437-1576-3404-9908', 175744941.000000, '2017-03-17 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (349, '7644-6681-1066-9493', 390323776.000000, '2016-11-11 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (350, '9027-9750-8145-5379', 272427491.000000, '2017-01-17 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (351, '8029-3357-1321-2734', 400248519.000000, '2017-03-06 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (352, '8447-8591-4374-9287', 334941052.000000, '2016-12-16 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (353, '9956-5857-4936-7706', 423992203.000000, '2016-08-05 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (354, '7029-1545-0892-4400', 379089229.000000, '2016-12-14 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (355, '7668-8112-2077-8420', 264369537.000000, '2016-08-07 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (356, '4100-6594-6717-1670', 210799303.000000, '2016-12-21 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (357, '0947-0978-6525-5862', 382121110.000000, '2016-08-09 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (358, '5461-3866-0547-6212', 247895572.000000, '2017-06-07 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (359, '3779-1660-9901-5439', 391164611.000000, '2016-12-08 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (360, '3202-8785-7610-1620', 295638532.000000, '2017-01-29 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (361, '7634-2860-1941-8213', 324777481.000000, '2016-12-14 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (362, '8255-9599-2397-2235', 213320043.000000, '2017-04-20 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (363, '2691-9297-6444-7373', 435949346.000000, '2016-09-11 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (364, '7553-1142-5366-4335', 188096365.000000, '2016-08-21 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (365, '4314-0768-0987-6657', 212101373.000000, '2016-12-16 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (366, '4767-9095-0546-9814', 280614856.000000, '2017-04-28 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (367, '3985-9819-3116-5865', 312392692.000000, '2017-07-10 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (368, '7847-2436-8417-7320', 438467390.000000, '2017-01-16 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (369, '5330-5848-7591-3934', 344141538.000000, '2017-03-15 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (370, '5572-5438-7645-6397', 388285803.000000, '2016-10-19 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (371, '9333-5118-1529-7984', 246220409.000000, '2016-11-20 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (372, '5759-8945-6212-8937', 264990968.000000, '2016-11-11 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (373, '8395-3917-3255-9601', 219278102.000000, '2016-08-30 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (374, '4131-2373-0165-9478', 402644874.000000, '2017-03-11 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (375, '5033-5983-6056-9695', 179430387.000000, '2017-04-28 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (376, '0960-7222-9969-6257', 332409300.000000, '2017-03-03 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (377, '5486-6285-1590-0991', 344655111.000000, '2016-09-26 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (378, '4698-6390-5786-6178', 343624050.000000, '2017-04-23 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (379, '4342-2780-7568-5225', 384147264.000000, '2017-06-08 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (380, '7518-6779-3429-9920', 430162351.000000, '2016-08-07 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (381, '3088-3945-1440-3580', 211204688.000000, '2017-04-17 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (382, '4408-0595-7155-9372', 400068642.000000, '2016-08-29 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (383, '1033-2607-6812-4756', 207497762.000000, '2017-02-17 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (384, '3351-8284-2471-0010', 339599406.000000, '2017-07-04 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (385, '0634-8834-4770-5595', 337018322.000000, '2017-07-26 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (386, '1208-7236-2812-7101', 397681860.000000, '2017-03-13 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (387, '7122-1814-6549-4560', 261159523.000000, '2016-12-04 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (388, '6768-3643-4256-4220', 242451264.000000, '2017-08-01 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (389, '8591-9284-0584-6791', 323459284.000000, '2016-11-28 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (390, '6777-1760-8793-1361', 435070416.000000, '2017-08-05 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (391, '3523-3487-9241-1570', 153724439.000000, '2017-06-17 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (392, '2917-8025-4648-5433', 184748750.000000, '2016-10-19 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (393, '3322-4897-9107-1728', 342264718.000000, '2017-06-01 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (394, '1715-3197-2111-3732', 251000097.000000, '2016-11-21 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (395, '6097-8025-5355-8835', 291145191.000000, '2016-08-29 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (396, '0608-5823-5376-5827', 323507507.000000, '2017-07-10 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (397, '1715-3747-1720-3476', 308082694.000000, '2016-08-11 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (398, '6190-5949-0687-4935', 223897302.000000, '2016-11-16 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (399, '9021-7503-0770-8770', 171420113.000000, '2017-06-03 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (400, '4290-0070-6740-7625', 245148594.000000, '2017-07-21 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (401, '0666-9829-4314-5827', 223734510.000000, '2016-10-29 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (402, '9627-0264-8010-2775', 438449690.000000, '2017-05-31 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (403, '9663-7399-2659-9823', 335760091.000000, '2016-11-07 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (404, '3855-6910-5022-2536', 263969951.000000, '2017-01-15 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (405, '4279-6890-8395-1948', 230824232.000000, '2016-11-12 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (406, '6435-6102-6448-7735', 234204354.000000, '2017-01-06 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (407, '6311-4328-5738-9003', 449651337.000000, '2017-01-21 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (408, '2848-2744-0190-5423', 284138763.000000, '2017-01-24 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (409, '8873-8169-5351-4597', 441338271.000000, '2017-02-02 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (410, '4043-0854-4270-8728', 323327155.000000, '2016-08-28 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (411, '8474-4826-4105-1942', 396267421.000000, '2016-12-24 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (412, '1695-8142-0494-1325', 328616366.000000, '2016-11-24 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (413, '8949-2140-6063-1411', 412856644.000000, '2017-06-02 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (414, '4054-9689-4325-5539', 336429231.000000, '2016-12-31 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (415, '2555-8595-1981-5035', 279917228.000000, '2016-11-22 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (416, '8605-4497-9671-2082', 395835951.000000, '2016-09-22 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (417, '5244-2130-6489-3790', 211061983.000000, '2016-12-31 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (418, '4928-3149-3924-5463', 191282841.000000, '2016-10-10 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (419, '5005-5947-1669-7433', 286184010.000000, '2017-07-16 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (420, '3647-6351-8394-2616', 358391222.000000, '2016-12-29 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (421, '6891-4271-1973-2374', 316128298.000000, '2016-12-18 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (422, '9450-2942-2446-0134', 184906488.000000, '2016-12-20 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (423, '6492-8933-7311-0833', 157474069.000000, '2017-05-15 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (424, '5466-0802-3043-9209', 405682728.000000, '2017-07-09 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (425, '3000-3455-2371-2202', 438882100.000000, '2017-06-16 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (426, '6129-3758-3370-1064', 355632090.000000, '2017-03-29 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (427, '4951-5075-6890-1921', 385859893.000000, '2016-11-25 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (428, '8808-7037-4636-5458', 366359313.000000, '2016-11-26 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (429, '8342-8916-6091-0997', 378696745.000000, '2017-06-01 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (430, '4102-3571-7578-9316', 240047070.000000, '2016-11-10 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (431, '6007-5744-6350-7012', 343882369.000000, '2017-07-12 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (432, '7550-2771-7686-5389', 279293962.000000, '2017-06-04 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (433, '8624-3519-7073-8889', 198436461.000000, '2017-06-25 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (434, '4951-7728-4865-7119', 421186569.000000, '2017-07-23 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (435, '4210-9603-8763-2613', 436892736.000000, '2017-05-12 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (436, '0453-2833-3985-5714', 352375818.000000, '2017-01-07 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (437, '3215-9131-3810-9645', 393543822.000000, '2016-12-04 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (438, '9437-9631-0215-9569', 235232931.000000, '2017-07-18 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (439, '6111-8936-1243-3669', 165771011.000000, '2017-04-04 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (440, '4913-8360-5886-2583', 376122726.000000, '2016-11-14 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (441, '1630-2763-2918-1826', 228808899.000000, '2017-03-26 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (442, '0467-4180-3844-5016', 333293541.000000, '2016-11-29 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (443, '6711-5787-2026-3049', 328718190.000000, '2017-08-02 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (444, '8016-7570-0156-5732', 264874481.000000, '2016-08-17 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (445, '5312-6857-8329-4307', 231662131.000000, '2017-01-23 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (446, '8492-1601-9003-0722', 264933266.000000, '2017-01-23 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (447, '1850-5689-4698-5360', 354467331.000000, '2016-09-16 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (448, '5549-7201-3406-2052', 310032935.000000, '2017-02-12 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (449, '2145-0817-1806-5619', 308516414.000000, '2017-02-21 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (450, '3386-4862-5982-2134', 224922367.000000, '2016-10-07 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (451, '8133-2840-6789-4226', 257593611.000000, '2017-04-11 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (452, '4207-6401-0561-6908', 157929038.000000, '2016-11-30 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (453, '0918-4472-2848-7283', 215831972.000000, '2017-06-21 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (454, '1747-5102-2907-6287', 396094952.000000, '2017-03-13 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (455, '0409-6333-1242-5641', 200498856.000000, '2016-12-20 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (456, '2301-0035-4173-7602', 192545733.000000, '2016-08-29 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (457, '0972-2060-7570-4742', 424884469.000000, '2017-02-09 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (458, '8400-7278-4743-0412', 424025627.000000, '2016-09-03 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (459, '1630-0325-3078-1771', 335046015.000000, '2016-08-27 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (460, '9762-0319-9292-3843', 199686725.000000, '2017-06-30 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (461, '3055-9395-0551-1743', 391354619.000000, '2016-10-12 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (462, '3690-3934-5226-0835', 319713797.000000, '2017-08-03 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (463, '6618-0714-7209-2612', 429551620.000000, '2017-04-12 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (464, '8312-8004-6508-8521', 359788405.000000, '2017-06-17 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (465, '6475-6514-2453-4835', 237811872.000000, '2017-04-29 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (466, '8378-6768-8364-3911', 445733429.000000, '2016-10-18 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (467, '4005-4766-2723-3197', 443105466.000000, '2017-05-16 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (468, '0687-8276-6997-1825', 333788675.000000, '2016-12-16 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (469, '7990-8986-5243-0174', 358808901.000000, '2017-03-03 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (470, '6362-1048-2724-2482', 256754366.000000, '2017-02-09 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (471, '1103-8690-6162-9912', 244183305.000000, '2017-07-27 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (472, '9312-3571-8136-5150', 301688718.000000, '2017-05-13 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (473, '2541-3883-4415-5470', 207646699.000000, '2016-08-27 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (474, '1155-5855-4355-6453', 306460224.000000, '2017-02-05 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (475, '0481-3816-5327-8449', 253391451.000000, '2016-08-13 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (476, '7768-6079-3106-5111', 252774780.000000, '2016-09-22 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (477, '9976-0588-1601-7673', 186607104.000000, '2016-12-15 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (478, '9463-7248-4089-1277', 154296773.000000, '2016-08-20 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (479, '5537-9720-1139-0893', 321287886.000000, '2017-08-05 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (480, '4478-6872-9766-2388', 185267043.000000, '2017-04-19 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (481, '5737-9930-3751-6329', 250682819.000000, '2016-10-22 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (482, '4465-3058-5886-7856', 428597405.000000, '2017-02-25 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (483, '8745-2834-9122-8299', 299668909.000000, '2016-08-26 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (484, '3562-0267-9135-6995', 172320516.000000, '2017-02-25 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (485, '5830-2732-8025-4631', 200221854.000000, '2017-04-09 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (486, '7306-9992-1336-8948', 212072768.000000, '2017-04-09 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (487, '1082-9900-0565-9255', 266135185.000000, '2016-11-05 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (488, '8466-9796-9588-7753', 199124142.000000, '2017-02-01 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (489, '0356-9831-7390-6579', 209928916.000000, '2016-12-10 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (490, '8468-1656-5592-5265', 397892126.000000, '2017-04-20 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (491, '9213-9472-8334-0889', 319093691.000000, '2016-08-19 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (492, '8721-1513-2509-7767', 341991807.000000, '2016-11-02 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (493, '3546-4779-2181-9597', 213633818.000000, '2017-03-21 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (494, '4568-2630-8285-9226', 156774499.000000, '2016-12-24 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (495, '8682-7001-7740-8714', 366661960.000000, '2017-01-01 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (496, '0403-3112-9590-3201', 430527137.000000, '2016-12-09 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (497, '2018-6394-5751-8840', 213473562.000000, '2017-03-26 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (498, '7572-5956-2301-9837', 314975021.000000, '2017-04-05 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (499, '2138-4325-5167-1782', 358539258.000000, '2016-08-02 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (500, '5844-8348-1804-8665', 228921653.000000, '2017-05-26 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (501, '4640-0341-9387-5781', 279018361.000000, '2017-01-31 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (502, '1630-2511-2937-7299', 226732665.000000, '2017-06-30 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (503, '6592-7866-3024-5314', 302720036.000000, '2017-01-18 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (504, '1475-4858-1691-5789', 234368031.000000, '2016-08-13 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (505, '3992-3343-8699-1754', 405556355.000000, '2017-07-26 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (506, '9065-8351-4489-8687', 275422078.000000, '2016-08-16 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (507, '2928-4331-8647-0560', 428825729.000000, '2017-03-10 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (508, '7173-6253-2005-9312', 252812845.000000, '2017-02-02 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (509, '6939-8463-2899-6921', 204208443.000000, '2017-05-07 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (510, '1215-0877-5497-4162', 189207628.000000, '2016-12-07 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (511, '2632-3183-7851-1820', 303474504.000000, '2016-10-22 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (512, '9935-9879-2260-2925', 391867027.000000, '2017-01-10 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (513, '9964-7808-5543-3283', 387622308.000000, '2017-03-27 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (514, '1029-9774-2970-1730', 321989653.000000, '2017-04-14 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (515, '4542-3132-7580-5698', 165941039.000000, '2017-02-28 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (516, '5476-9906-2825-9952', 448826884.000000, '2017-03-20 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (517, '3730-3787-8629-3917', 392643998.000000, '2017-07-04 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (518, '1178-7900-5881-6552', 263663050.000000, '2017-07-09 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (519, '5318-9901-9863-4382', 236109717.000000, '2016-08-22 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (520, '0350-1117-8856-7980', 348115087.000000, '2017-03-20 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (521, '6583-2282-3212-0467', 292280048.000000, '2016-08-29 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (522, '1541-4277-0660-4459', 346256415.000000, '2016-12-22 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (523, '9590-2625-2150-7258', 296837001.000000, '2016-12-10 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (524, '0636-0754-0405-3314', 278282233.000000, '2016-10-03 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (525, '2363-7005-2893-4182', 272572186.000000, '2017-01-02 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (526, '1683-9992-4718-7113', 227707983.000000, '2016-11-03 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (527, '5095-6341-6973-5274', 311620271.000000, '2017-03-20 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (528, '9181-1189-4069-8436', 402772816.000000, '2016-10-15 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (529, '1866-9428-1104-6886', 319929078.000000, '2017-04-17 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (530, '8278-7710-7311-4788', 171059249.000000, '2017-03-05 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (531, '4064-9491-1791-9866', 183223391.000000, '2017-02-04 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (532, '0117-2729-2666-4999', 235104643.000000, '2016-08-12 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (533, '9455-7519-9184-1316', 170427380.000000, '2016-11-13 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (534, '4489-2174-0669-7685', 446632744.000000, '2017-06-21 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (535, '6760-5797-6026-8236', 385563202.000000, '2017-03-23 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (536, '0475-0347-5867-3706', 256197190.000000, '2017-03-14 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (537, '1164-3535-1779-9752', 360218519.000000, '2017-04-19 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (538, '8918-2649-5470-5706', 344449686.000000, '2016-08-20 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (539, '6499-7973-8172-6081', 334736355.000000, '2017-03-24 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (540, '8466-6269-4466-4874', 431627879.000000, '2017-03-05 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (541, '9999-8370-6668-7190', 262457671.000000, '2016-10-02 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (542, '7116-7842-3370-2242', 192934181.000000, '2016-09-26 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (543, '7761-2171-6893-8685', 167124650.000000, '2017-07-27 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (544, '7486-5639-1437-3118', 187123330.000000, '2017-07-23 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (545, '3407-5270-2479-7393', 230986732.000000, '2017-04-06 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (546, '2079-4572-9595-5154', 220920587.000000, '2016-09-28 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (547, '6758-7942-1548-0121', 230860357.000000, '2017-05-12 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (548, '9591-3296-4863-4542', 383623771.000000, '2016-09-23 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (549, '1189-7024-1496-1936', 224066346.000000, '2017-02-12 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (550, '2632-8850-8767-6806', 257108504.000000, '2017-05-09 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (551, '9505-0277-8346-3969', 323318962.000000, '2017-01-24 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (552, '2139-8397-7084-4093', 173546030.000000, '2017-04-20 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (553, '8496-8115-5596-9722', 196376089.000000, '2017-05-25 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (554, '1078-8795-8240-6760', 314184046.000000, '2017-05-17 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (555, '6447-3132-2386-3059', 421651495.000000, '2016-11-19 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (556, '4868-7136-8392-3176', 374991117.000000, '2017-01-15 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (557, '3803-6035-3793-4001', 403018109.000000, '2017-05-05 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (558, '4491-5667-1554-9630', 231980118.000000, '2017-07-28 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (559, '0268-5280-7709-0786', 248853822.000000, '2017-04-15 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (560, '8949-3946-3107-0179', 434901228.000000, '2016-09-16 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (561, '6121-8028-2625-4222', 157905083.000000, '2016-09-24 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (562, '8745-0201-1661-2523', 205490430.000000, '2017-05-20 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (563, '4935-1821-8202-2968', 328385017.000000, '2017-04-11 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (564, '6746-5524-6238-5271', 380058637.000000, '2016-08-17 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (565, '3526-8802-4949-4634', 266478393.000000, '2017-07-23 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (566, '7664-2611-7081-6632', 262232146.000000, '2017-06-11 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (567, '6541-5717-5729-7113', 164262446.000000, '2017-04-28 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (568, '3372-1461-3357-0143', 415653489.000000, '2016-09-24 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (569, '9689-1520-0552-2257', 435310048.000000, '2016-10-25 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (570, '2802-2131-5201-0271', 410065970.000000, '2016-09-16 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (571, '5206-5934-1915-3021', 256769551.000000, '2017-02-19 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (572, '6491-2184-3317-1931', 324220829.000000, '2016-10-31 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (573, '6635-4746-9618-9316', 229105867.000000, '2017-06-07 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (574, '3368-0816-3360-9187', 394092062.000000, '2016-08-11 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (575, '5428-5398-1935-2463', 169662118.000000, '2016-08-29 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (576, '2650-5157-3672-6578', 439719637.000000, '2017-04-23 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (577, '4192-8466-3559-0834', 161058126.000000, '2016-12-31 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (578, '8203-9351-1310-1235', 449836799.000000, '2016-10-22 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (579, '9400-6128-0621-5409', 246536403.000000, '2017-06-05 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (580, '4119-6950-3561-4992', 330259521.000000, '2016-09-14 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (581, '0346-9608-7387-6327', 436267927.000000, '2016-08-23 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (582, '5622-1722-7571-8255', 190781674.000000, '2016-09-03 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (583, '8959-5852-1379-0192', 311807892.000000, '2017-03-18 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (584, '6557-7799-9961-8218', 171912409.000000, '2017-02-15 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (585, '0514-4787-8982-4300', 273233155.000000, '2016-12-21 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (586, '0140-4923-2389-0727', 384919882.000000, '2017-03-26 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (587, '3780-0383-1667-6535', 282144605.000000, '2016-08-30 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (588, '1986-8035-6874-7565', 250166662.000000, '2017-04-12 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (589, '0820-4587-6824-7985', 422923625.000000, '2017-03-14 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (590, '4452-2795-2853-9523', 214038625.000000, '2017-01-25 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (591, '7401-6719-2903-4065', 241842968.000000, '2017-03-14 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (592, '9363-1099-8826-5566', 191155439.000000, '2016-08-06 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (593, '1123-4560-6785-9543', 185367944.000000, '2017-07-22 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (594, '5551-1019-1170-6548', 244071022.000000, '2016-08-10 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (595, '6313-3080-5678-3858', 190966590.000000, '2017-01-09 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (596, '4710-8990-0069-3222', 383740281.000000, '2017-04-16 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (597, '1363-2180-8920-1867', 363309188.000000, '2017-07-25 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (598, '0181-2541-5255-2584', 391777401.000000, '2016-12-17 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (599, '7665-4361-2051-0234', 341201465.000000, '2016-10-29 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (600, '3671-1051-5487-3782', 336867288.000000, '2017-01-20 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (601, '6424-8071-9108-4502', 232764900.000000, '2016-10-24 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (602, '7820-4469-0702-7629', 162085340.000000, '2017-03-23 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (603, '8208-5994-1776-8085', 320301527.000000, '2017-01-09 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (604, '4981-4577-3614-8588', 224664346.000000, '2016-10-02 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (605, '7328-1152-9776-2856', 358151062.000000, '2017-06-08 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (606, '5477-1421-8772-8324', 404360971.000000, '2016-09-23 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (607, '9319-6402-6367-9643', 341868206.000000, '2016-10-01 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (608, '0692-8676-7680-5833', 175205865.000000, '2017-08-05 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (609, '6853-1210-7083-5530', 432761019.000000, '2017-03-27 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (610, '2107-2630-0013-7168', 274313650.000000, '2017-04-02 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (611, '2530-4884-4726-8684', 372673934.000000, '2017-01-08 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (612, '9153-0285-9063-5908', 298142186.000000, '2016-09-29 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (613, '0074-8367-8071-1220', 434677862.000000, '2017-06-22 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (614, '0081-7911-8197-5581', 154088991.000000, '2017-04-15 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (615, '2893-6865-7692-8052', 186684841.000000, '2016-09-17 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (616, '8730-6745-7677-0461', 246569258.000000, '2016-12-23 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (617, '1405-4442-6573-5897', 407867393.000000, '2017-07-31 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (618, '1648-0781-3078-1877', 296792945.000000, '2017-07-07 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (619, '8309-1029-1985-4355', 428733691.000000, '2017-03-01 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (620, '2221-0754-3973-1051', 429458840.000000, '2016-08-05 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (621, '4785-7858-5902-0580', 288926035.000000, '2016-10-29 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (622, '9452-0825-2091-3906', 320025294.000000, '2017-03-01 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (623, '7790-6384-6955-0766', 376320849.000000, '2017-04-26 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (624, '2329-7925-9726-5030', 324483112.000000, '2016-08-25 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (625, '6642-6674-6250-1202', 422182567.000000, '2016-12-25 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (626, '3925-5240-3610-2141', 210868255.000000, '2017-07-29 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (627, '6415-4192-3179-9426', 253673046.000000, '2017-03-21 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (628, '5952-2699-9699-3113', 168217480.000000, '2017-06-29 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (629, '0841-2249-8886-5338', 240227575.000000, '2016-12-11 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (630, '3304-1266-4460-0809', 159526545.000000, '2017-04-08 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (631, '7591-2485-8429-7497', 426873481.000000, '2016-09-22 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (632, '7872-2526-6619-2504', 218898213.000000, '2017-03-11 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (633, '8208-5565-5813-1453', 428356507.000000, '2016-08-15 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (634, '6761-5503-3356-1971', 350325887.000000, '2016-08-09 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (635, '9446-5312-0194-9512', 354092274.000000, '2016-08-28 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (636, '4593-9532-3041-7011', 427803664.000000, '2016-08-01 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (637, '1373-6024-9204-8582', 193463419.000000, '2017-07-30 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (638, '9564-8786-5763-0311', 204531534.000000, '2016-11-23 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (639, '6889-0041-6232-5724', 315135445.000000, '2017-04-15 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (640, '4377-0106-3176-8044', 397762552.000000, '2017-07-18 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (641, '0093-0717-7855-8621', 173317977.000000, '2016-10-30 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (642, '5498-8953-4099-5133', 247915219.000000, '2017-04-13 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (643, '4159-0519-3146-3812', 389323309.000000, '2016-09-10 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (644, '2177-9204-5855-2340', 190834979.000000, '2016-11-08 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (645, '4408-7236-9916-1891', 295582733.000000, '2017-02-16 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (646, '0822-7068-9243-8891', 218506979.000000, '2017-03-31 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (647, '1780-2902-1963-8625', 285040283.000000, '2016-08-11 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (648, '9704-9929-7178-8103', 246845251.000000, '2017-05-11 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (649, '1778-8428-8990-5968', 439725846.000000, '2017-04-12 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (650, '0177-7899-6206-8106', 254064978.000000, '2017-06-23 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (651, '9899-9870-2438-3478', 349378158.000000, '2017-05-21 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (652, '4170-9568-1904-9980', 367321040.000000, '2016-11-12 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (653, '9827-9591-6662-0112', 376444353.000000, '2016-09-26 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (654, '9409-0563-8504-7287', 286518568.000000, '2017-02-18 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (655, '9811-1722-5045-0670', 297115566.000000, '2016-09-13 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (656, '9350-0086-1238-0376', 177238551.000000, '2017-03-12 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (657, '3605-7164-4531-3983', 184802010.000000, '2017-06-25 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (658, '2387-4116-3699-0044', 368794821.000000, '2017-07-11 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (659, '4327-3699-3991-5248', 224044404.000000, '2016-11-26 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (660, '8057-8052-0967-7029', 189012941.000000, '2017-04-23 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (661, '2125-2796-8386-1777', 348313127.000000, '2017-05-20 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (662, '7111-5132-7995-5089', 245045029.000000, '2016-08-05 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (663, '4305-2519-0729-1255', 176070821.000000, '2017-07-02 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (664, '2819-7576-2967-7617', 430917273.000000, '2017-02-22 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (665, '7600-5534-7912-7650', 320671431.000000, '2016-10-07 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (666, '0031-0825-4207-7451', 161643049.000000, '2017-01-17 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (667, '9494-1375-9599-2451', 160132875.000000, '2016-12-25 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (668, '7785-2013-9754-1083', 200188976.000000, '2017-02-24 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (669, '6690-3842-6103-9519', 387751904.000000, '2017-04-01 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (670, '2639-9433-6813-5967', 186547688.000000, '2017-03-31 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (671, '6646-0588-6217-9747', 173258849.000000, '2017-03-11 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (672, '6549-6805-4081-8635', 366727639.000000, '2017-03-06 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (673, '8004-0166-8784-4683', 263824751.000000, '2017-07-09 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (674, '8881-4291-1393-9206', 314737363.000000, '2017-04-28 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (675, '1628-4469-4254-4255', 248966218.000000, '2017-02-18 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (676, '8552-0405-6197-9901', 379615148.000000, '2016-09-18 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (677, '9883-5961-6517-4010', 416079483.000000, '2017-03-31 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (678, '3084-3732-4361-0086', 216429000.000000, '2017-07-25 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (679, '0746-0674-7223-5619', 330445942.000000, '2017-01-11 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (680, '2280-1779-0471-5318', 375456976.000000, '2017-04-20 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (681, '5545-1357-9636-3169', 301768126.000000, '2017-05-30 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (682, '3583-8213-4143-9711', 335717766.000000, '2017-07-29 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (683, '5081-7006-2463-0217', 200251407.000000, '2017-05-08 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (684, '0625-5789-0933-9728', 236855450.000000, '2017-02-01 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (685, '0140-2787-6477-4524', 340671755.000000, '2017-03-29 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (686, '4821-3301-7746-1349', 351297614.000000, '2017-02-06 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (687, '9606-1585-2060-8079', 412156823.000000, '2017-01-17 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (688, '5467-3923-1765-7151', 343673963.000000, '2016-12-29 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (689, '0097-7698-8413-7348', 182782321.000000, '2017-03-31 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (690, '1508-2064-2026-7610', 321264967.000000, '2016-12-31 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (691, '0276-7149-2926-4746', 300985803.000000, '2016-10-16 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (692, '5345-1932-3298-5325', 291570086.000000, '2016-10-02 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (693, '6387-3084-2819-5638', 442968178.000000, '2017-03-09 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (694, '2374-2534-7359-2444', 166225590.000000, '2017-06-26 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (695, '8263-6894-0909-0911', 272090741.000000, '2016-11-12 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (696, '3376-3270-3265-3518', 317543468.000000, '2017-08-05 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (697, '6941-1137-1293-6653', 336913973.000000, '2017-08-03 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (698, '0075-6185-1037-6321', 240057994.000000, '2017-05-25 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (699, '1100-7332-6663-8295', 373604456.000000, '2017-01-19 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (700, '8580-4430-7584-2750', 313795697.000000, '2016-12-30 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (701, '9392-5951-1261-6862', 418964249.000000, '2017-01-19 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (702, '6208-3887-9872-0419', 426504361.000000, '2017-01-17 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (703, '5998-1286-0435-2887', 256952372.000000, '2017-01-24 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (704, '8722-1029-6046-2103', 189520187.000000, '2016-10-17 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (705, '6876-3354-5583-1458', 448581024.000000, '2017-03-13 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (706, '3915-5119-8398-0697', 393385682.000000, '2017-03-13 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (707, '6879-9953-6602-9061', 380746018.000000, '2016-11-28 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (708, '2998-6007-0135-7091', 285363368.000000, '2016-09-17 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (709, '7016-8978-9924-1613', 244243923.000000, '2017-04-25 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (710, '3535-2449-5558-7697', 211952296.000000, '2016-12-05 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (711, '8000-2272-1003-6653', 235171583.000000, '2017-06-27 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (712, '0941-9567-9911-0938', 286002748.000000, '2017-05-07 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (713, '9865-7398-8744-4357', 166649424.000000, '2016-12-21 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (714, '4348-8697-9298-2108', 439022059.000000, '2016-08-20 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (715, '6953-0000-0012-2654', 348806290.000000, '2016-10-25 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (716, '9372-1718-0849-8844', 341295828.000000, '2017-05-21 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (717, '5374-2352-9131-4756', 335272804.000000, '2017-04-09 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (718, '4490-3980-7238-8700', 191343871.000000, '2016-12-05 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (719, '4759-7971-8874-1491', 439301580.000000, '2016-08-10 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (720, '5414-2120-4147-4860', 191105018.000000, '2017-04-19 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (721, '6771-5490-2874-7421', 409709026.000000, '2016-10-11 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (722, '6130-3140-1930-7167', 432526170.000000, '2016-12-09 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (723, '7671-7317-0267-7964', 264540415.000000, '2017-04-13 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (724, '1679-2509-6968-7377', 374487521.000000, '2016-10-22 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (725, '7366-7385-3876-8415', 347407982.000000, '2017-02-12 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (726, '6735-0858-7744-7994', 161089248.000000, '2017-04-05 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (727, '9047-7506-0162-0489', 268466328.000000, '2017-03-28 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (728, '7881-2895-3447-1545', 176463945.000000, '2017-06-12 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (729, '1244-3751-3519-7016', 295274709.000000, '2017-04-20 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (730, '7800-5498-7867-5837', 285131469.000000, '2016-08-05 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (731, '1218-5597-4263-9081', 387232573.000000, '2016-09-16 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (732, '5123-5612-7316-1987', 152855547.000000, '2016-09-06 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (733, '0605-9991-1349-8896', 385323133.000000, '2017-06-04 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (734, '6024-2414-7844-5037', 349091220.000000, '2016-09-07 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (735, '3564-5733-3113-4933', 422280213.000000, '2016-11-26 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (736, '3163-6133-3780-5137', 230700001.000000, '2016-11-26 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (737, '7629-4189-1211-5218', 329378595.000000, '2017-06-14 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (738, '2370-4863-9564-5049', 249179227.000000, '2016-12-14 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (739, '6703-6438-5781-3618', 361761593.000000, '2016-08-03 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (740, '9512-2858-0859-3287', 242837413.000000, '2017-02-03 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (741, '7168-3838-8848-0614', 175268217.000000, '2016-09-09 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (742, '2425-7395-8704-0178', 155169048.000000, '2016-08-22 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (743, '3118-9370-9608-0660', 389907266.000000, '2017-05-12 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (744, '0714-1131-7491-7867', 248818901.000000, '2017-01-04 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (745, '3787-9057-2673-4768', 333059507.000000, '2017-07-04 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (746, '6926-2835-3378-2241', 423329411.000000, '2017-02-20 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (747, '6927-8165-6542-7138', 427677506.000000, '2016-12-01 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (748, '6288-7006-5475-6661', 287604139.000000, '2017-03-21 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (749, '1832-9622-2825-4224', 209487453.000000, '2016-12-25 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (750, '1232-4421-2594-5281', 286654671.000000, '2017-01-03 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (751, '1486-3459-0435-3155', 422133464.000000, '2017-06-08 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (752, '8910-8488-8040-7169', 432812736.000000, '2017-06-18 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (753, '6243-5359-5834-3643', 168205940.000000, '2016-09-13 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (754, '3349-8388-9044-8651', 273259083.000000, '2017-04-13 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (755, '3030-5344-0883-5346', 308072916.000000, '2017-04-16 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (756, '3652-8402-2084-3744', 217516575.000000, '2017-05-19 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (757, '1283-8610-4212-9730', 263796773.000000, '2016-10-15 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (758, '9634-2056-2795-7015', 185136597.000000, '2016-09-13 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (759, '5092-0727-0054-6347', 216194617.000000, '2017-01-01 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (760, '7589-0471-6735-5401', 290669302.000000, '2016-11-21 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (761, '7327-6841-6103-5107', 264499299.000000, '2017-01-19 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (762, '7998-0816-9249-5992', 213827391.000000, '2016-10-03 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (763, '9156-2306-0183-0385', 177657782.000000, '2017-04-10 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (764, '2379-6060-8267-7139', 281131400.000000, '2016-09-09 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (765, '1772-4265-0104-8486', 178787508.000000, '2016-11-23 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (766, '5835-9233-7689-1111', 436482774.000000, '2017-07-29 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (767, '2109-5322-2196-3482', 153456124.000000, '2017-07-25 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (768, '8602-7362-1082-6366', 221543814.000000, '2017-03-09 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (769, '6576-6280-8889-9108', 402004396.000000, '2017-03-23 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (770, '7056-7918-1988-2836', 237167240.000000, '2017-01-12 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (771, '4709-7969-4885-5187', 281006835.000000, '2016-10-08 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (772, '8327-1459-3640-6015', 408225880.000000, '2017-04-13 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (773, '9261-3382-3016-6082', 428489429.000000, '2016-12-03 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (774, '2491-7738-6169-4478', 256648369.000000, '2017-04-25 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (775, '2543-2609-9528-0688', 360595104.000000, '2016-09-15 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (776, '0077-8382-6894-1833', 193516960.000000, '2017-05-12 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (777, '6186-9891-1392-0544', 426584953.000000, '2016-08-10 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (778, '0207-6599-6207-7293', 394700778.000000, '2016-11-25 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (779, '6847-4825-8553-5681', 223974119.000000, '2017-06-02 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (780, '7786-2488-0114-3528', 210097129.000000, '2017-06-03 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (781, '1293-6124-3978-4095', 269228113.000000, '2016-09-19 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (782, '6555-6816-0646-2682', 219883115.000000, '2017-07-01 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (783, '9924-9845-7043-6223', 357328039.000000, '2016-12-27 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (784, '7923-5977-0907-5796', 195959158.000000, '2017-03-18 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (785, '0560-4661-1372-3656', 231292690.000000, '2017-07-23 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (786, '5500-1286-3789-0175', 381759410.000000, '2017-06-06 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (787, '2612-5828-0172-4289', 264902403.000000, '2016-12-09 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (788, '4990-7591-5046-9079', 401198674.000000, '2017-04-12 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (789, '0684-6111-7709-1157', 337325598.000000, '2016-08-30 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (790, '0303-9744-5598-1034', 342731219.000000, '2016-08-05 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (791, '1143-1930-0572-7289', 331828466.000000, '2017-02-09 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (792, '5213-1946-6403-3553', 190192144.000000, '2016-09-25 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (793, '5832-6937-3216-6329', 192655539.000000, '2016-12-23 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (794, '9218-1566-1068-6049', 207235941.000000, '2016-08-05 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (795, '8711-8195-4783-1092', 432839168.000000, '2017-02-14 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (796, '3232-3396-8859-4945', 221206506.000000, '2017-01-05 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (797, '4551-2589-7606-5608', 280044092.000000, '2017-04-14 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (798, '0798-4948-4656-4453', 373077236.000000, '2017-05-20 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (799, '8284-5047-3214-2991', 154133669.000000, '2017-01-25 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (800, '3891-5908-7556-6405', 242936514.000000, '2017-02-28 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (801, '8950-2285-5040-4032', 401220474.000000, '2016-09-14 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (802, '5166-2374-5347-4160', 202367116.000000, '2017-02-20 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (803, '0495-0274-6737-9516', 289405269.000000, '2017-06-18 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (804, '2792-9059-5930-6484', 366787033.000000, '2016-08-16 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (805, '3897-2818-7764-7654', 358805847.000000, '2017-06-14 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (806, '8728-0284-9812-6524', 258408489.000000, '2016-10-17 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (807, '1810-2868-6592-1860', 300638573.000000, '2017-03-12 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (808, '2226-7529-2167-0371', 404163202.000000, '2017-01-13 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (809, '2864-4811-5832-3298', 320990144.000000, '2016-08-25 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (810, '0519-8443-6363-4791', 422395540.000000, '2017-03-13 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (811, '5568-2696-5810-0516', 359009468.000000, '2016-10-02 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (812, '6904-6818-2252-3788', 332729578.000000, '2016-10-06 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (813, '8438-2972-3579-8814', 192545745.000000, '2017-07-26 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (814, '2705-5302-1866-9530', 225249963.000000, '2017-03-25 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (815, '8351-7638-6418-0664', 247547361.000000, '2017-06-16 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (816, '2952-6640-6879-5318', 282816732.000000, '2016-11-17 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (817, '9955-6247-5740-6265', 266787860.000000, '2017-02-28 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (818, '1006-8363-7959-5345', 444590591.000000, '2017-03-03 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (819, '4152-6436-1853-4550', 326112373.000000, '2017-01-13 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (820, '8192-2341-2023-3195', 256459457.000000, '2016-11-25 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (821, '5146-4727-1765-5050', 410043130.000000, '2017-06-05 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (822, '1212-1898-2182-5009', 328918292.000000, '2016-12-17 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (823, '4469-1115-0179-3752', 353059345.000000, '2017-02-28 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (824, '3578-5937-5577-4200', 183133435.000000, '2016-11-14 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (825, '7603-4214-2216-1711', 387214692.000000, '2016-12-25 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (826, '3231-5665-9336-4930', 341539977.000000, '2017-07-27 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (827, '5706-5268-7517-7328', 190771352.000000, '2017-03-02 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (828, '0500-8267-0385-3204', 330204139.000000, '2017-03-03 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (829, '4041-1655-5923-0729', 419138493.000000, '2017-08-05 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (830, '8376-7939-9428-9693', 226941736.000000, '2017-05-02 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (831, '6669-0305-6209-5818', 398815806.000000, '2016-10-22 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (832, '9191-8786-5106-0667', 360789534.000000, '2017-07-28 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (833, '6949-2008-3748-8577', 193306935.000000, '2017-04-15 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (834, '1895-4646-2215-5779', 232252993.000000, '2016-11-15 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (835, '3938-0252-3933-7528', 268656178.000000, '2016-11-03 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (836, '5255-9094-5380-8858', 351247293.000000, '2016-11-05 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (837, '7213-3694-2680-3233', 187093392.000000, '2017-06-30 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (838, '5063-8232-6239-0150', 158082758.000000, '2017-05-04 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (839, '6914-6780-2252-4531', 386460954.000000, '2017-05-18 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (840, '9237-4423-9181-6079', 310570555.000000, '2017-04-27 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (841, '6846-6981-4048-7296', 238599927.000000, '2016-11-03 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (842, '8970-0470-8363-0744', 206653428.000000, '2016-11-16 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (843, '1259-1754-5933-9904', 342863768.000000, '2017-06-14 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (844, '6736-4528-6431-4990', 442941608.000000, '2017-04-02 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (845, '9603-6566-4780-2484', 416908962.000000, '2017-05-08 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (846, '4303-2080-5179-6157', 408627235.000000, '2017-03-29 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (847, '0026-2816-9564-1013', 234003942.000000, '2016-10-16 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (848, '2437-1576-3404-9908', 376318057.000000, '2017-01-23 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (849, '7644-6681-1066-9493', 193326504.000000, '2017-01-02 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (850, '9027-9750-8145-5379', 308886837.000000, '2017-05-12 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (851, '8029-3357-1321-2734', 212255166.000000, '2017-03-08 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (852, '8447-8591-4374-9287', 405409783.000000, '2016-09-04 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (853, '9956-5857-4936-7706', 241614425.000000, '2017-07-25 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (854, '7029-1545-0892-4400', 312205736.000000, '2017-02-06 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (855, '7668-8112-2077-8420', 218891857.000000, '2017-03-25 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (856, '4100-6594-6717-1670', 352095631.000000, '2017-04-15 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (857, '0947-0978-6525-5862', 318415743.000000, '2016-11-13 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (858, '5461-3866-0547-6212', 370913233.000000, '2017-02-17 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (859, '3779-1660-9901-5439', 375569471.000000, '2016-10-25 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (860, '3202-8785-7610-1620', 268650600.000000, '2017-02-09 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (861, '7634-2860-1941-8213', 402369704.000000, '2017-07-09 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (862, '8255-9599-2397-2235', 203870944.000000, '2017-01-28 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (863, '2691-9297-6444-7373', 421937900.000000, '2016-08-25 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (864, '7553-1142-5366-4335', 237213591.000000, '2016-11-02 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (865, '4314-0768-0987-6657', 331867632.000000, '2016-09-04 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (866, '4767-9095-0546-9814', 437769073.000000, '2016-12-26 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (867, '3985-9819-3116-5865', 449124675.000000, '2017-05-06 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (868, '7847-2436-8417-7320', 234345883.000000, '2016-11-13 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (869, '5330-5848-7591-3934', 257630896.000000, '2017-05-30 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (870, '5572-5438-7645-6397', 158347994.000000, '2017-04-19 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (871, '9333-5118-1529-7984', 399081551.000000, '2016-08-24 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (872, '5759-8945-6212-8937', 422450409.000000, '2017-05-07 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (873, '8395-3917-3255-9601', 432523522.000000, '2017-02-11 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (874, '4131-2373-0165-9478', 196915805.000000, '2017-07-13 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (875, '5033-5983-6056-9695', 154569925.000000, '2016-09-04 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (876, '0960-7222-9969-6257', 357773947.000000, '2017-06-13 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (877, '5486-6285-1590-0991', 379979269.000000, '2017-01-02 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (878, '4698-6390-5786-6178', 449114857.000000, '2016-11-28 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (879, '4342-2780-7568-5225', 202378124.000000, '2017-03-23 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (880, '7518-6779-3429-9920', 447588638.000000, '2017-03-24 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (881, '3088-3945-1440-3580', 246323243.000000, '2017-06-29 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (882, '4408-0595-7155-9372', 350852508.000000, '2017-01-22 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (883, '1033-2607-6812-4756', 442721531.000000, '2016-09-22 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (884, '3351-8284-2471-0010', 251362339.000000, '2017-01-16 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (885, '0634-8834-4770-5595', 245880732.000000, '2017-06-26 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (886, '1208-7236-2812-7101', 342225560.000000, '2017-07-20 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (887, '7122-1814-6549-4560', 158481378.000000, '2017-06-03 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (888, '6768-3643-4256-4220', 183265235.000000, '2017-07-30 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (889, '8591-9284-0584-6791', 369236615.000000, '2017-03-07 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (890, '6777-1760-8793-1361', 287595756.000000, '2017-07-09 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (891, '3523-3487-9241-1570', 218808688.000000, '2017-04-26 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (892, '2917-8025-4648-5433', 445107937.000000, '2016-12-04 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (893, '3322-4897-9107-1728', 380567004.000000, '2016-12-12 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (894, '1715-3197-2111-3732', 428213245.000000, '2017-06-14 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (895, '6097-8025-5355-8835', 277155642.000000, '2017-01-20 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (896, '0608-5823-5376-5827', 237267449.000000, '2017-02-17 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (897, '1715-3747-1720-3476', 227124435.000000, '2017-03-26 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (898, '6190-5949-0687-4935', 423255196.000000, '2016-09-01 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (899, '9021-7503-0770-8770', 204725233.000000, '2017-05-10 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (900, '4290-0070-6740-7625', 200470381.000000, '2017-01-30 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (901, '0666-9829-4314-5827', 206163962.000000, '2017-06-18 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (902, '9627-0264-8010-2775', 420571332.000000, '2016-11-12 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (903, '9663-7399-2659-9823', 166899775.000000, '2017-08-04 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (904, '3855-6910-5022-2536', 181353969.000000, '2016-10-11 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (905, '4279-6890-8395-1948', 406447536.000000, '2017-03-10 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (906, '6435-6102-6448-7735', 187711573.000000, '2016-08-26 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (907, '6311-4328-5738-9003', 240312952.000000, '2016-09-22 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (908, '2848-2744-0190-5423', 249844133.000000, '2016-08-22 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (909, '8873-8169-5351-4597', 229243154.000000, '2017-07-05 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (910, '4043-0854-4270-8728', 155700862.000000, '2016-09-10 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (911, '8474-4826-4105-1942', 266177143.000000, '2017-04-26 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (912, '1695-8142-0494-1325', 241968397.000000, '2017-05-02 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (913, '8949-2140-6063-1411', 295435968.000000, '2017-01-12 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (914, '4054-9689-4325-5539', 449445172.000000, '2017-06-03 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (915, '2555-8595-1981-5035', 351396856.000000, '2017-07-17 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (916, '8605-4497-9671-2082', 426093471.000000, '2017-03-03 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (917, '5244-2130-6489-3790', 158359540.000000, '2017-07-25 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (918, '4928-3149-3924-5463', 437663968.000000, '2016-11-09 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (919, '5005-5947-1669-7433', 321591309.000000, '2016-08-23 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (920, '3647-6351-8394-2616', 184199006.000000, '2016-11-07 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (921, '6891-4271-1973-2374', 207271563.000000, '2017-07-31 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (922, '9450-2942-2446-0134', 325587262.000000, '2017-04-15 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (923, '6492-8933-7311-0833', 264951104.000000, '2017-03-09 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (924, '5466-0802-3043-9209', 205366247.000000, '2017-04-10 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (925, '3000-3455-2371-2202', 227444614.000000, '2017-04-14 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (926, '6129-3758-3370-1064', 417574380.000000, '2017-01-22 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (927, '4951-5075-6890-1921', 410741319.000000, '2017-04-27 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (928, '8808-7037-4636-5458', 236083163.000000, '2017-01-04 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (929, '8342-8916-6091-0997', 410435018.000000, '2017-02-24 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (930, '4102-3571-7578-9316', 408130741.000000, '2016-12-25 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (931, '6007-5744-6350-7012', 190737236.000000, '2017-03-31 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (932, '7550-2771-7686-5389', 239393093.000000, '2016-11-20 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (933, '8624-3519-7073-8889', 207209423.000000, '2017-03-08 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (934, '4951-7728-4865-7119', 262410534.000000, '2016-09-06 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (935, '4210-9603-8763-2613', 268648973.000000, '2016-10-07 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (936, '0453-2833-3985-5714', 262482562.000000, '2017-05-23 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (937, '3215-9131-3810-9645', 257245675.000000, '2016-10-14 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (938, '9437-9631-0215-9569', 355338558.000000, '2017-02-15 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (939, '6111-8936-1243-3669', 174519496.000000, '2017-03-31 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (940, '4913-8360-5886-2583', 286813449.000000, '2016-10-30 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (941, '1630-2763-2918-1826', 204956904.000000, '2016-11-20 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (942, '0467-4180-3844-5016', 424740944.000000, '2016-11-17 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (943, '6711-5787-2026-3049', 186111978.000000, '2017-06-29 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (944, '8016-7570-0156-5732', 313621099.000000, '2016-10-14 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (945, '5312-6857-8329-4307', 321349264.000000, '2016-09-11 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (946, '8492-1601-9003-0722', 150839469.000000, '2016-09-12 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (947, '1850-5689-4698-5360', 326007385.000000, '2016-10-10 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (948, '5549-7201-3406-2052', 153408218.000000, '2016-08-11 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (949, '2145-0817-1806-5619', 311857789.000000, '2017-06-20 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (950, '3386-4862-5982-2134', 293418404.000000, '2017-03-14 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (951, '8133-2840-6789-4226', 278906823.000000, '2017-05-18 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (952, '4207-6401-0561-6908', 165750382.000000, '2017-02-13 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (953, '0918-4472-2848-7283', 256765657.000000, '2016-10-10 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (954, '1747-5102-2907-6287', 213633801.000000, '2017-02-01 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (955, '0409-6333-1242-5641', 209449537.000000, '2016-11-03 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (956, '2301-0035-4173-7602', 353540400.000000, '2017-06-16 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (957, '0972-2060-7570-4742', 154161911.000000, '2017-03-03 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (958, '8400-7278-4743-0412', 382866884.000000, '2017-05-16 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (959, '1630-0325-3078-1771', 268192787.000000, '2017-06-13 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (960, '9762-0319-9292-3843', 181196593.000000, '2016-09-27 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (961, '3055-9395-0551-1743', 419365595.000000, '2017-03-27 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (962, '3690-3934-5226-0835', 212221606.000000, '2017-02-25 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (963, '6618-0714-7209-2612', 426106225.000000, '2017-03-09 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (964, '8312-8004-6508-8521', 326554690.000000, '2017-05-16 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (965, '6475-6514-2453-4835', 172427378.000000, '2016-11-11 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (966, '8378-6768-8364-3911', 414620809.000000, '2017-02-23 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (967, '4005-4766-2723-3197', 322738367.000000, '2016-11-28 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (968, '0687-8276-6997-1825', 174917514.000000, '2017-05-25 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (969, '7990-8986-5243-0174', 280519297.000000, '2017-03-27 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (970, '6362-1048-2724-2482', 192886830.000000, '2017-03-04 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (971, '1103-8690-6162-9912', 150255529.000000, '2017-05-06 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (972, '9312-3571-8136-5150', 302474600.000000, '2016-08-20 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (973, '2541-3883-4415-5470', 206741433.000000, '2017-02-16 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (974, '1155-5855-4355-6453', 259907633.000000, '2016-09-27 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (975, '0481-3816-5327-8449', 391507741.000000, '2016-10-20 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (976, '7768-6079-3106-5111', 223022930.000000, '2017-04-15 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (977, '9976-0588-1601-7673', 400472087.000000, '2016-12-11 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (978, '9463-7248-4089-1277', 217805640.000000, '2016-11-18 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (979, '5537-9720-1139-0893', 419516796.000000, '2017-02-28 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (980, '4478-6872-9766-2388', 371090794.000000, '2017-03-15 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (981, '5737-9930-3751-6329', 396845718.000000, '2017-03-25 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (982, '4465-3058-5886-7856', 292276738.000000, '2016-09-28 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (983, '8745-2834-9122-8299', 418556930.000000, '2017-03-10 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (984, '3562-0267-9135-6995', 189321893.000000, '2017-06-17 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (985, '5830-2732-8025-4631', 201116357.000000, '2017-02-25 00:00:00', 'aanlaynu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (986, '7306-9992-1336-8948', 208656618.000000, '2017-05-25 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (987, '1082-9900-0565-9255', 292488885.000000, '2016-09-21 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (988, '8466-9796-9588-7753', 355216222.000000, '2017-05-16 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (989, '0356-9831-7390-6579', 176877379.000000, '2016-11-21 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (990, '8468-1656-5592-5265', 386507152.000000, '2017-04-26 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (991, '9213-9472-8334-0889', 227383659.000000, '2017-01-12 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (992, '8721-1513-2509-7767', 156995253.000000, '2017-03-02 00:00:00', 'aalanbrooke3q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (993, '3546-4779-2181-9597', 308297894.000000, '2016-11-28 00:00:00', 'aadamoco', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (994, '4568-2630-8285-9226', 221881729.000000, '2017-04-27 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (995, '8682-7001-7740-8714', 421385859.000000, '2016-11-14 00:00:00', 'aalanbrooke3q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (996, '0403-3112-9590-3201', 244614120.000000, '2017-05-20 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (997, '2018-6394-5751-8840', 178308655.000000, '2017-01-05 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (998, '7572-5956-2301-9837', 172022822.000000, '2017-07-31 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (999, '2138-4325-5167-1782', 296924655.000000, '2016-11-21 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1000, '5844-8348-1804-8665', 209719085.000000, '2016-08-04 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1001, '4640-0341-9387-5781', 412446624.000000, '2017-03-10 00:00:00', 'mchipps4t', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1002, '1630-2511-2937-7299', 421703001.000000, '2016-11-07 00:00:00', 'bpiolaqi', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1003, '6592-7866-3024-5314', 428886780.000000, '2017-07-12 00:00:00', 'acrallanck', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1004, '1475-4858-1691-5789', 367907721.000000, '2016-10-26 00:00:00', 'sdevasqn', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1005, '3992-3343-8699-1754', 196870335.000000, '2017-07-17 00:00:00', 'dberthonkk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1006, '9065-8351-4489-8687', 435251108.000000, '2017-01-26 00:00:00', 'rsibthorpgh', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1007, '2928-4331-8647-0560', 254620615.000000, '2016-11-17 00:00:00', 'eloades6b', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1008, '7173-6253-2005-9312', 354162337.000000, '2016-12-19 00:00:00', 'kwilmut6x', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1009, '6939-8463-2899-6921', 161219070.000000, '2017-06-22 00:00:00', 'gslowlyc2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1010, '1215-0877-5497-4162', 241061014.000000, '2016-12-31 00:00:00', 'gmckuelk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1011, '2632-3183-7851-1820', 382402953.000000, '2016-11-01 00:00:00', 'ukernockecx', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1012, '9935-9879-2260-2925', 405186352.000000, '2017-04-06 00:00:00', 'cnevinsna', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1013, '9964-7808-5543-3283', 173736394.000000, '2016-12-23 00:00:00', 'ohearlen5', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1014, '1029-9774-2970-1730', 430829258.000000, '2017-04-09 00:00:00', 'adonlonm5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1015, '4542-3132-7580-5698', 205158633.000000, '2017-01-12 00:00:00', 'bdumingoscf', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1016, '5476-9906-2825-9952', 362982854.000000, '2017-04-14 00:00:00', 'twenham82', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1017, '3730-3787-8629-3917', 246037895.000000, '2017-03-08 00:00:00', 'amcaughtryj2', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1018, '1178-7900-5881-6552', 340822548.000000, '2017-08-07 00:00:00', 'wcattermolel3', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1019, '5318-9901-9863-4382', 290784178.000000, '2017-05-24 00:00:00', 'jphysick33', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1020, '0350-1117-8856-7980', 429426854.000000, '2016-12-14 00:00:00', 'blightbodyfj', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1021, '6583-2282-3212-0467', 153335985.000000, '2016-11-03 00:00:00', 'ejacmar5t', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1022, '1541-4277-0660-4459', 211319850.000000, '2017-05-24 00:00:00', 'mscarlon2k', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1023, '9590-2625-2150-7258', 291763262.000000, '2016-09-11 00:00:00', 'gmelmothbg', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1024, '0636-0754-0405-3314', 244614257.000000, '2016-12-06 00:00:00', 'mpoletto3c', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1025, '2363-7005-2893-4182', 224655539.000000, '2016-12-27 00:00:00', 'mbonnysonmh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1026, '1683-9992-4718-7113', 198116101.000000, '2016-12-29 00:00:00', 'mmitroshinov29', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1027, '5095-6341-6973-5274', 436129994.000000, '2017-07-05 00:00:00', 'sthebeaudbp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1028, '9181-1189-4069-8436', 200095419.000000, '2016-08-10 00:00:00', 'fsirman9v', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1029, '1866-9428-1104-6886', 201841751.000000, '2017-03-09 00:00:00', 'mdadgelq', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1030, '8278-7710-7311-4788', 390845001.000000, '2017-04-08 00:00:00', 'shamill8q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1031, '4064-9491-1791-9866', 347357374.000000, '2016-08-08 00:00:00', 'otheobaldj7', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1032, '0117-2729-2666-4999', 259955925.000000, '2017-07-18 00:00:00', 'iskynerpc', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1033, '9455-7519-9184-1316', 313007640.000000, '2016-09-29 00:00:00', 'tdiboll5g', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1034, '4489-2174-0669-7685', 192599653.000000, '2016-08-17 00:00:00', 'lwinfredn9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1035, '6760-5797-6026-8236', 220693201.000000, '2017-07-19 00:00:00', 'mdashpermb', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1036, '0475-0347-5867-3706', 248841228.000000, '2017-02-06 00:00:00', 'aosbanjr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1037, '1164-3535-1779-9752', 154490245.000000, '2016-10-26 00:00:00', 'ebrettlepn', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1038, '8918-2649-5470-5706', 425206428.000000, '2016-10-29 00:00:00', 'amoff5n', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1039, '6499-7973-8172-6081', 216470360.000000, '2017-04-25 00:00:00', 'emarien57', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1040, '8466-6269-4466-4874', 410774043.000000, '2017-01-18 00:00:00', 'pswane61', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1041, '9999-8370-6668-7190', 298792997.000000, '2016-11-19 00:00:00', 'jpartington47', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1042, '7116-7842-3370-2242', 264994663.000000, '2017-05-11 00:00:00', 'vstreetgw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1043, '7761-2171-6893-8685', 320228789.000000, '2017-02-13 00:00:00', 'hdaffornem0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1044, '7486-5639-1437-3118', 425431290.000000, '2017-02-05 00:00:00', 'pprobyncg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1045, '3407-5270-2479-7393', 162645460.000000, '2016-12-19 00:00:00', 'shamill8q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1046, '2079-4572-9595-5154', 189709763.000000, '2017-08-03 00:00:00', 'sizzetthc', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1047, '6758-7942-1548-0121', 165906959.000000, '2016-09-04 00:00:00', 'cvickersm7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1048, '9591-3296-4863-4542', 371890831.000000, '2017-05-04 00:00:00', 'blej', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1049, '1189-7024-1496-1936', 413581817.000000, '2017-03-19 00:00:00', 'aworsfieldfv', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1050, '2632-8850-8767-6806', 327496650.000000, '2017-07-13 00:00:00', 'igerholdpf', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1051, '9505-0277-8346-3969', 266437297.000000, '2016-11-04 00:00:00', 'tcoffeerp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1052, '2139-8397-7084-4093', 197700986.000000, '2017-07-12 00:00:00', 'dbaymanow', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1053, '8496-8115-5596-9722', 191945879.000000, '2017-02-13 00:00:00', 'ctolerel', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1054, '1078-8795-8240-6760', 177593200.000000, '2017-01-06 00:00:00', 'eobroganegi', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1055, '6447-3132-2386-3059', 362197296.000000, '2017-01-11 00:00:00', 'tglidden93', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1056, '4868-7136-8392-3176', 325657999.000000, '2017-02-03 00:00:00', 'aarnett2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1057, '3803-6035-3793-4001', 371030763.000000, '2016-08-27 00:00:00', 'vohoolahan51', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1058, '4491-5667-1554-9630', 182263561.000000, '2017-04-28 00:00:00', 'trizzinik9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1059, '0268-5280-7709-0786', 382632414.000000, '2017-05-25 00:00:00', 'motridgeky', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1060, '8949-3946-3107-0179', 269578328.000000, '2016-09-09 00:00:00', 'dtitteringtonbw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1061, '6121-8028-2625-4222', 155211811.000000, '2016-11-19 00:00:00', 'zschusterlft', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1062, '8745-0201-1661-2523', 253288160.000000, '2017-05-23 00:00:00', 'semneymr', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1063, '4935-1821-8202-2968', 351418834.000000, '2017-07-29 00:00:00', 'gvest5m', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1064, '6746-5524-6238-5271', 415456176.000000, '2016-08-23 00:00:00', 'hbalharry4b', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1065, '3526-8802-4949-4634', 437989807.000000, '2016-11-17 00:00:00', 'estarmorejm', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1066, '7664-2611-7081-6632', 223964277.000000, '2017-05-01 00:00:00', 'etubblepb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1067, '6541-5717-5729-7113', 292336963.000000, '2016-09-04 00:00:00', 'featockim', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1068, '3372-1461-3357-0143', 441547457.000000, '2016-11-09 00:00:00', 'ctommasuzzijs', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1069, '9689-1520-0552-2257', 241874116.000000, '2016-11-30 00:00:00', 'rasletqd', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1070, '2802-2131-5201-0271', 271076753.000000, '2017-03-18 00:00:00', 'kdecourcyi9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1071, '5206-5934-1915-3021', 340915362.000000, '2017-07-14 00:00:00', 'kpeschetgx', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1072, '6491-2184-3317-1931', 375606720.000000, '2017-02-27 00:00:00', 'mdudbridgel5', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1073, '6635-4746-9618-9316', 361610814.000000, '2016-12-21 00:00:00', 'sdevasqn', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1074, '3368-0816-3360-9187', 215615582.000000, '2017-07-18 00:00:00', 'aaizikovitz9q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1075, '5428-5398-1935-2463', 263685160.000000, '2016-12-09 00:00:00', 'brosencrantz1e', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1076, '2650-5157-3672-6578', 362170063.000000, '2017-06-15 00:00:00', 'tansettqk', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1077, '4192-8466-3559-0834', 184873739.000000, '2016-12-29 00:00:00', 'prennelsfu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1078, '8203-9351-1310-1235', 261105790.000000, '2017-07-21 00:00:00', 'daslieqw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1079, '9400-6128-0621-5409', 287026065.000000, '2017-03-24 00:00:00', 'hnajafianp3', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1080, '4119-6950-3561-4992', 241667436.000000, '2017-07-28 00:00:00', 'taizlewoodbm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1081, '0346-9608-7387-6327', 438591587.000000, '2017-07-04 00:00:00', 'lbloxland21', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1082, '5622-1722-7571-8255', 409854439.000000, '2016-09-24 00:00:00', 'trakestrawfl', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1083, '8959-5852-1379-0192', 244201908.000000, '2017-02-01 00:00:00', 'lpatersonnn', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1084, '6557-7799-9961-8218', 376803458.000000, '2017-07-27 00:00:00', 'zwhiteson6y', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1085, '0514-4787-8982-4300', 285931338.000000, '2017-03-28 00:00:00', 'mmussettinie0', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1086, '0140-4923-2389-0727', 326705952.000000, '2017-02-15 00:00:00', 'hshewonho', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1087, '3780-0383-1667-6535', 324507937.000000, '2016-08-26 00:00:00', 'jquinanei2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1088, '1986-8035-6874-7565', 307916822.000000, '2017-02-27 00:00:00', 'mduchesnehz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1089, '0820-4587-6824-7985', 165863768.000000, '2016-11-30 00:00:00', 'miviedz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1090, '4452-2795-2853-9523', 292628656.000000, '2017-01-25 00:00:00', 'omccardlef5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1091, '7401-6719-2903-4065', 359229052.000000, '2017-01-02 00:00:00', 'dstrowlgerz', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1092, '9363-1099-8826-5566', 174017370.000000, '2016-11-20 00:00:00', 'gboullin7u', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1093, '1123-4560-6785-9543', 267664282.000000, '2016-12-27 00:00:00', 'bbyrth8s', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1094, '5551-1019-1170-6548', 409356124.000000, '2017-02-23 00:00:00', 'affoulkes83', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1095, '6313-3080-5678-3858', 273858679.000000, '2017-03-28 00:00:00', 'ctucsellj3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1096, '4710-8990-0069-3222', 196095345.000000, '2017-02-21 00:00:00', 'mearsman1n', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1097, '1363-2180-8920-1867', 253943163.000000, '2017-06-14 00:00:00', 'sdimmne88', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1098, '0181-2541-5255-2584', 227232360.000000, '2017-06-10 00:00:00', 'tludgrovede', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1099, '7665-4361-2051-0234', 319380950.000000, '2017-07-07 00:00:00', 'zingleson4y', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1100, '3671-1051-5487-3782', 235453242.000000, '2017-04-24 00:00:00', 'pfeltoego', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1101, '6424-8071-9108-4502', 220843492.000000, '2016-08-29 00:00:00', 'dghelardig1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1102, '7820-4469-0702-7629', 182639816.000000, '2017-06-19 00:00:00', 'disoldi9i', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1103, '8208-5994-1776-8085', 153550904.000000, '2017-03-19 00:00:00', 'kyouleg', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1104, '4981-4577-3614-8588', 288848709.000000, '2017-06-08 00:00:00', 'do8c', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1105, '7328-1152-9776-2856', 155151763.000000, '2017-06-04 00:00:00', 'tgilardonell', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1106, '5477-1421-8772-8324', 252547913.000000, '2017-01-20 00:00:00', 'sdrewsqq', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1107, '9319-6402-6367-9643', 243776641.000000, '2016-12-08 00:00:00', 'jcowleh3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1108, '0692-8676-7680-5833', 338357323.000000, '2017-03-12 00:00:00', 'nsnaith3', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1109, '6853-1210-7083-5530', 377512216.000000, '2016-11-25 00:00:00', 'rcholominju', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1110, '2107-2630-0013-7168', 346062900.000000, '2017-01-26 00:00:00', 'jblaxelandp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1111, '2530-4884-4726-8684', 399931003.000000, '2017-07-06 00:00:00', 'ggladtbach4v', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1112, '9153-0285-9063-5908', 164508358.000000, '2017-03-21 00:00:00', 'dcorrisong0', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1113, '0074-8367-8071-1220', 259362803.000000, '2017-06-02 00:00:00', 'edealeydp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1114, '0081-7911-8197-5581', 228001096.000000, '2017-03-22 00:00:00', 'jfairbeard34', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1115, '2893-6865-7692-8052', 384421722.000000, '2017-01-11 00:00:00', 'zmasiox', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1116, '8730-6745-7677-0461', 445487648.000000, '2017-06-22 00:00:00', 'mida3x', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1117, '1405-4442-6573-5897', 444509291.000000, '2016-08-04 00:00:00', 'gcattoncr', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1118, '1648-0781-3078-1877', 329555609.000000, '2016-09-19 00:00:00', 'alubyay', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1119, '8309-1029-1985-4355', 412241856.000000, '2017-05-18 00:00:00', 'mdudbridgel5', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1120, '2221-0754-3973-1051', 191495302.000000, '2017-02-22 00:00:00', 'vwiltshawml', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1121, '4785-7858-5902-0580', 391963931.000000, '2017-04-13 00:00:00', 'scaile7p', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1122, '9452-0825-2091-3906', 398124154.000000, '2016-08-25 00:00:00', 'bwickwarthg8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1123, '7790-6384-6955-0766', 205057009.000000, '2017-03-20 00:00:00', 'aloisib4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1124, '2329-7925-9726-5030', 355620239.000000, '2016-12-09 00:00:00', 'othorpe8e', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1125, '6642-6674-6250-1202', 182860193.000000, '2017-07-26 00:00:00', 'lsmoutena7', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1126, '3925-5240-3610-2141', 342148695.000000, '2016-10-01 00:00:00', 'kcornejobs', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1127, '6415-4192-3179-9426', 331173481.000000, '2017-03-15 00:00:00', 'hlameyom', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1128, '5952-2699-9699-3113', 240205972.000000, '2016-12-18 00:00:00', 'gbaribal7k', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1129, '0841-2249-8886-5338', 303303482.000000, '2016-09-01 00:00:00', 'lhitteria', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1130, '3304-1266-4460-0809', 411152518.000000, '2016-10-08 00:00:00', 'nhugeninjx', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1131, '7591-2485-8429-7497', 343058319.000000, '2017-05-29 00:00:00', 'tenzleymz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1132, '7872-2526-6619-2504', 266167163.000000, '2017-04-10 00:00:00', 'gvaskovmw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1133, '8208-5565-5813-1453', 299668262.000000, '2016-08-23 00:00:00', 'dcahnhm', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1134, '6761-5503-3356-1971', 158076147.000000, '2016-08-05 00:00:00', 'zingleson4y', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1135, '9446-5312-0194-9512', 386244613.000000, '2017-06-13 00:00:00', 'tchelamu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1136, '4593-9532-3041-7011', 281171926.000000, '2017-01-18 00:00:00', 'ethirkettleij', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1137, '1373-6024-9204-8582', 418366813.000000, '2017-07-24 00:00:00', 'cgoning6q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1138, '9564-8786-5763-0311', 247916203.000000, '2016-09-22 00:00:00', 'cyettsbi', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1139, '6889-0041-6232-5724', 212444094.000000, '2016-12-01 00:00:00', 'smenureil', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1140, '4377-0106-3176-8044', 316671916.000000, '2016-09-26 00:00:00', 'lwinfredn9', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1141, '0093-0717-7855-8621', 303692324.000000, '2017-08-07 00:00:00', 'amuddfq', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1142, '5498-8953-4099-5133', 297870486.000000, '2016-11-25 00:00:00', 'eloades6b', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1143, '4159-0519-3146-3812', 258953283.000000, '2017-03-24 00:00:00', 'uyerrallmj', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1144, '2177-9204-5855-2340', 417377783.000000, '2016-11-15 00:00:00', 'czavatterorl', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1145, '4408-7236-9916-1891', 241554465.000000, '2016-11-15 00:00:00', 'sburnhamsp6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1146, '0822-7068-9243-8891', 434349466.000000, '2017-05-18 00:00:00', 'lzanettohs', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1147, '1780-2902-1963-8625', 227061366.000000, '2016-10-25 00:00:00', 'gmckuelk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1148, '9704-9929-7178-8103', 321839377.000000, '2017-01-30 00:00:00', 'glamswood3y', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1149, '1778-8428-8990-5968', 346952794.000000, '2017-02-21 00:00:00', 'bfyers55', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1150, '0177-7899-6206-8106', 173497619.000000, '2017-02-20 00:00:00', 'vshalec4', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1151, '9899-9870-2438-3478', 360750870.000000, '2017-07-15 00:00:00', 'brosencrantz1e', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1152, '4170-9568-1904-9980', 213292081.000000, '2017-01-19 00:00:00', 'cleverson2z', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1153, '9827-9591-6662-0112', 357277704.000000, '2016-12-28 00:00:00', 'gsertinda', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1154, '9409-0563-8504-7287', 306760114.000000, '2016-12-11 00:00:00', 'kbaldacchie2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1155, '9811-1722-5045-0670', 416102708.000000, '2016-11-01 00:00:00', 'wglazierd3', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1156, '9350-0086-1238-0376', 362361025.000000, '2016-12-01 00:00:00', 'nspieghtnt', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1157, '3605-7164-4531-3983', 376848998.000000, '2017-01-15 00:00:00', 'kwalterq0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1158, '2387-4116-3699-0044', 203720738.000000, '2016-10-22 00:00:00', 'acoalesf4', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1159, '4327-3699-3991-5248', 264510711.000000, '2016-10-01 00:00:00', 'squigah', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1160, '8057-8052-0967-7029', 274493200.000000, '2016-11-03 00:00:00', 'mdimitrescuop', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1161, '2125-2796-8386-1777', 275177061.000000, '2016-09-10 00:00:00', 'caisthorpe25', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1162, '7111-5132-7995-5089', 326684257.000000, '2017-06-12 00:00:00', 'mbernatd2', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1163, '4305-2519-0729-1255', 309776272.000000, '2016-10-05 00:00:00', 'mswindenf', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1164, '2819-7576-2967-7617', 330357732.000000, '2017-04-24 00:00:00', 'cshobbrook7e', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1165, '7600-5534-7912-7650', 285685079.000000, '2017-03-08 00:00:00', 'egoodding1k', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1166, '0031-0825-4207-7451', 286091705.000000, '2017-05-14 00:00:00', 'lmcramseygv', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1167, '9494-1375-9599-2451', 284148904.000000, '2017-05-06 00:00:00', 'iodreaino6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1168, '7785-2013-9754-1083', 342572681.000000, '2016-12-28 00:00:00', 'jduigenano3', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1169, '6690-3842-6103-9519', 415180993.000000, '2017-05-09 00:00:00', 'fchueem', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1170, '2639-9433-6813-5967', 184798987.000000, '2017-07-27 00:00:00', 'dpaulsener', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1171, '6646-0588-6217-9747', 333207060.000000, '2017-05-18 00:00:00', 'scoultl4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1172, '6549-6805-4081-8635', 432103827.000000, '2016-10-05 00:00:00', 'jchapple2e', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1173, '8004-0166-8784-4683', 294891666.000000, '2017-08-01 00:00:00', 'qtilll6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1174, '8881-4291-1393-9206', 191402772.000000, '2016-09-17 00:00:00', 'tokellyc8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1175, '1628-4469-4254-4255', 281606263.000000, '2017-08-04 00:00:00', 'tsidnell2l', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1176, '8552-0405-6197-9901', 236940971.000000, '2017-06-11 00:00:00', 'yyurocjkinlh', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1177, '9883-5961-6517-4010', 354038408.000000, '2017-01-24 00:00:00', 'lgiamoec', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1178, '3084-3732-4361-0086', 333658088.000000, '2017-06-28 00:00:00', 'akeerl9o', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1179, '0746-0674-7223-5619', 283007484.000000, '2016-08-19 00:00:00', 'yreaperq9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1180, '2280-1779-0471-5318', 243508790.000000, '2017-06-08 00:00:00', 'pyve7a', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1181, '5545-1357-9636-3169', 235238284.000000, '2016-11-13 00:00:00', 'abengallke', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1182, '3583-8213-4143-9711', 210241872.000000, '2017-03-30 00:00:00', 'zingleson4y', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1183, '5081-7006-2463-0217', 256706489.000000, '2017-04-04 00:00:00', 'bbattermy', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1184, '0625-5789-0933-9728', 172684897.000000, '2017-01-10 00:00:00', 'tbaptistare', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1185, '0140-2787-6477-4524', 192801701.000000, '2016-10-24 00:00:00', 'wnicklinsonhn', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1186, '4821-3301-7746-1349', 431163946.000000, '2016-11-21 00:00:00', 'hkilbourneoo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1187, '9606-1585-2060-8079', 181944241.000000, '2017-01-20 00:00:00', 'cmaryetnd', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1188, '5467-3923-1765-7151', 423941517.000000, '2017-06-16 00:00:00', 'jaleshkov42', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1189, '0097-7698-8413-7348', 266391966.000000, '2017-04-27 00:00:00', 'kpapaf9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1190, '1508-2064-2026-7610', 201894507.000000, '2017-01-15 00:00:00', 'abreenk3', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1191, '0276-7149-2926-4746', 199272158.000000, '2016-12-08 00:00:00', 'lkinneally1x', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1192, '5345-1932-3298-5325', 191185279.000000, '2017-05-03 00:00:00', 'gcaneg5', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1193, '6387-3084-2819-5638', 428580898.000000, '2017-06-28 00:00:00', 'wnicklinsonhn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1194, '2374-2534-7359-2444', 191981199.000000, '2017-01-03 00:00:00', 'rthackerayhy', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1195, '8263-6894-0909-0911', 157200026.000000, '2017-07-16 00:00:00', 'ckuhleig', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1196, '3376-3270-3265-3518', 405120962.000000, '2017-04-22 00:00:00', 'mfarndaleff', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1197, '6941-1137-1293-6653', 324818002.000000, '2017-07-23 00:00:00', 'zwhiteson6y', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1198, '0075-6185-1037-6321', 443158383.000000, '2017-06-30 00:00:00', 'gcampsall8o', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1199, '1100-7332-6663-8295', 290394260.000000, '2016-11-03 00:00:00', 'mhalfordba', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1200, '8580-4430-7584-2750', 226258549.000000, '2016-10-16 00:00:00', 'denburyee', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1201, '9392-5951-1261-6862', 153540579.000000, '2016-10-24 00:00:00', 'ihallumjv', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1202, '6208-3887-9872-0419', 434121717.000000, '2017-03-03 00:00:00', 'glamswood3y', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1203, '5998-1286-0435-2887', 424747092.000000, '2016-10-04 00:00:00', 'kmckevin38', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1204, '8722-1029-6046-2103', 355949605.000000, '2017-02-28 00:00:00', 'lzanettohs', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1205, '6876-3354-5583-1458', 344605123.000000, '2017-07-25 00:00:00', 'sgilliattav', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1206, '3915-5119-8398-0697', 315861191.000000, '2017-03-05 00:00:00', 'sthebeaudbp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1207, '6879-9953-6602-9061', 277532600.000000, '2017-01-13 00:00:00', 'ckillingbeckoe', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1208, '2998-6007-0135-7091', 345721522.000000, '2016-11-25 00:00:00', 'fgingell2s', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1209, '7016-8978-9924-1613', 215184669.000000, '2016-11-03 00:00:00', 'dtowers3a', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1210, '3535-2449-5558-7697', 403427580.000000, '2017-05-27 00:00:00', 'hdaffornem0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1211, '8000-2272-1003-6653', 358607149.000000, '2017-02-02 00:00:00', 'po3n', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1212, '0941-9567-9911-0938', 171712385.000000, '2017-01-03 00:00:00', 'alippatt4z', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1213, '9865-7398-8744-4357', 440344408.000000, '2017-04-11 00:00:00', 'tdreelan58', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1214, '4348-8697-9298-2108', 422307359.000000, '2017-05-30 00:00:00', 'lclue2j', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1215, '6953-0000-0012-2654', 178523624.000000, '2016-10-17 00:00:00', 'pswane61', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1216, '9372-1718-0849-8844', 236636008.000000, '2017-07-25 00:00:00', 'smenureil', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1217, '5374-2352-9131-4756', 162014841.000000, '2017-07-10 00:00:00', 'lwinfredn9', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1218, '4490-3980-7238-8700', 406294893.000000, '2016-12-05 00:00:00', 'amackaig8j', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1219, '4759-7971-8874-1491', 163864410.000000, '2016-10-14 00:00:00', 'heicke4g', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1220, '5414-2120-4147-4860', 162079232.000000, '2017-01-07 00:00:00', 'hcutforthkx', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1221, '6771-5490-2874-7421', 341022585.000000, '2017-04-28 00:00:00', 'pprobyncg', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1222, '6130-3140-1930-7167', 269927172.000000, '2017-05-11 00:00:00', 'bmatthewscm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1223, '7671-7317-0267-7964', 240829509.000000, '2017-01-04 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1224, '1679-2509-6968-7377', 420382044.000000, '2017-04-27 00:00:00', 'mdibnahd9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1225, '7366-7385-3876-8415', 393723489.000000, '2017-07-18 00:00:00', 'czavatterorl', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1226, '6735-0858-7744-7994', 158638247.000000, '2017-02-15 00:00:00', 'lpennyman9w', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1227, '9047-7506-0162-0489', 446548210.000000, '2017-04-03 00:00:00', 'lpriumj9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1228, '7881-2895-3447-1545', 204091040.000000, '2017-07-14 00:00:00', 'dwittgl', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1229, '1244-3751-3519-7016', 172417577.000000, '2017-02-04 00:00:00', 'mdeeream', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1230, '7800-5498-7867-5837', 170572721.000000, '2016-10-11 00:00:00', 'mfolibr', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1231, '1218-5597-4263-9081', 431842961.000000, '2017-03-22 00:00:00', 'dskullyg4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1232, '5123-5612-7316-1987', 401206610.000000, '2017-06-18 00:00:00', 'mgarlicl9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1233, '0605-9991-1349-8896', 208995957.000000, '2017-01-26 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1234, '6024-2414-7844-5037', 406227730.000000, '2017-02-11 00:00:00', 'mraittp5', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1235, '3564-5733-3113-4933', 339456549.000000, '2017-04-02 00:00:00', 'ioharaqh', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1236, '3163-6133-3780-5137', 265751865.000000, '2016-10-06 00:00:00', 'sschwandermannm3', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1237, '7629-4189-1211-5218', 318775681.000000, '2017-01-06 00:00:00', 'lsmoutena7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1238, '2370-4863-9564-5049', 210756786.000000, '2017-01-20 00:00:00', 'kbaldacchie2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1239, '6703-6438-5781-3618', 155193885.000000, '2017-06-08 00:00:00', 'shalliburton1d', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1240, '9512-2858-0859-3287', 309987608.000000, '2016-12-08 00:00:00', 'aadamoco', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1241, '7168-3838-8848-0614', 212569973.000000, '2017-06-26 00:00:00', 'ssteptonp', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1242, '2425-7395-8704-0178', 183441861.000000, '2017-02-22 00:00:00', 'dlongridgehp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1243, '3118-9370-9608-0660', 431606999.000000, '2017-02-16 00:00:00', 'dghelardig1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1244, '0714-1131-7491-7867', 356775546.000000, '2017-03-23 00:00:00', 'bguppeyak', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1245, '3787-9057-2673-4768', 434871176.000000, '2017-04-06 00:00:00', 'tcoffeerp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1246, '6926-2835-3378-2241', 331198326.000000, '2017-08-01 00:00:00', 'hfairleighqc', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1247, '6927-8165-6542-7138', 317666747.000000, '2017-01-03 00:00:00', 'cashelfordhg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1248, '6288-7006-5475-6661', 163863773.000000, '2017-08-04 00:00:00', 'kjanovskykt', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1249, '1832-9622-2825-4224', 265349524.000000, '2016-10-27 00:00:00', 'marnaldyp9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1250, '1232-4421-2594-5281', 379819277.000000, '2016-11-20 00:00:00', 'uyerrallmj', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1251, '1486-3459-0435-3155', 164792382.000000, '2017-05-26 00:00:00', 'lmcramseygv', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1252, '8910-8488-8040-7169', 421685506.000000, '2017-04-20 00:00:00', 'nhugeninjx', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1253, '6243-5359-5834-3643', 153639785.000000, '2017-03-29 00:00:00', 'cmartyntsevaw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1254, '3349-8388-9044-8651', 214071072.000000, '2017-01-04 00:00:00', 'tgovern20', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1255, '3030-5344-0883-5346', 327875515.000000, '2017-07-05 00:00:00', 'fwedmoreqb', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1256, '3652-8402-2084-3744', 388622441.000000, '2017-06-16 00:00:00', 'cpykee7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1257, '1283-8610-4212-9730', 396744112.000000, '2017-06-13 00:00:00', 'jkiddey1z', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1258, '9634-2056-2795-7015', 328172077.000000, '2016-08-19 00:00:00', 'wdanilovitchjl', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1259, '5092-0727-0054-6347', 252266270.000000, '2017-03-30 00:00:00', 'sportamr1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1260, '7589-0471-6735-5401', 215350369.000000, '2016-08-18 00:00:00', 'nsousaja', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1261, '7327-6841-6103-5107', 447629743.000000, '2017-05-23 00:00:00', 'bemneybq', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1262, '7998-0816-9249-5992', 423701731.000000, '2017-01-10 00:00:00', 'czavatterorl', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1263, '9156-2306-0183-0385', 216523254.000000, '2017-04-19 00:00:00', 'rcaslindn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1264, '2379-6060-8267-7139', 262901459.000000, '2016-10-16 00:00:00', 'callbrook0', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1265, '1772-4265-0104-8486', 163274977.000000, '2017-04-03 00:00:00', 'spashler2m', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1266, '5835-9233-7689-1111', 267013211.000000, '2017-03-23 00:00:00', 'vjosefhl', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1267, '2109-5322-2196-3482', 244391900.000000, '2016-08-17 00:00:00', 'dputt84', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1268, '8602-7362-1082-6366', 278620746.000000, '2016-08-17 00:00:00', 'kyouleg', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1269, '6576-6280-8889-9108', 262095875.000000, '2017-03-25 00:00:00', 'olaphornoj', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1270, '7056-7918-1988-2836', 360833372.000000, '2017-04-23 00:00:00', 'hspittlesr2', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1271, '4709-7969-4885-5187', 224382294.000000, '2017-07-17 00:00:00', 'wlaurenty49', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1272, '8327-1459-3640-6015', 430596675.000000, '2016-11-28 00:00:00', 'fboardmanh9', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1273, '9261-3382-3016-6082', 297276468.000000, '2017-05-20 00:00:00', 'dtrounceea', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1274, '2491-7738-6169-4478', 229199288.000000, '2016-09-05 00:00:00', 'edealeydp', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1275, '2543-2609-9528-0688', 365997742.000000, '2016-12-17 00:00:00', 'bcollierbd', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1276, '0077-8382-6894-1833', 203439336.000000, '2017-05-20 00:00:00', 'mdanielsencc', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1277, '6186-9891-1392-0544', 167892281.000000, '2017-03-26 00:00:00', 'bbaystingny', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1278, '0207-6599-6207-7293', 271184996.000000, '2016-11-14 00:00:00', 'acanedo5u', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1279, '6847-4825-8553-5681', 160631661.000000, '2017-01-08 00:00:00', 'jbridgett9n', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1280, '7786-2488-0114-3528', 307699648.000000, '2016-12-09 00:00:00', 'asambrooka4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1281, '1293-6124-3978-4095', 235826455.000000, '2017-07-03 00:00:00', 'scarette86', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1282, '6555-6816-0646-2682', 250255170.000000, '2017-05-31 00:00:00', 'lelecum8h', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1283, '9924-9845-7043-6223', 328108184.000000, '2017-05-22 00:00:00', 'ajustmi', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1284, '7923-5977-0907-5796', 226115167.000000, '2016-12-01 00:00:00', 'sdarrigoeh8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1285, '0560-4661-1372-3656', 378827322.000000, '2016-09-03 00:00:00', 'gduffrie2w', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1286, '5500-1286-3789-0175', 267556134.000000, '2017-05-06 00:00:00', 'lbrisbane9x', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1287, '2612-5828-0172-4289', 280939018.000000, '2017-07-22 00:00:00', 'cvolkesol', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1288, '4990-7591-5046-9079', 398762436.000000, '2017-01-22 00:00:00', 'vkenealyqx', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1289, '0684-6111-7709-1157', 382273499.000000, '2016-12-09 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1290, '0303-9744-5598-1034', 153489799.000000, '2017-05-01 00:00:00', 'kprophetif', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1291, '1143-1930-0572-7289', 219737927.000000, '2017-06-27 00:00:00', 'cismirnioglou2p', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1292, '5213-1946-6403-3553', 276376327.000000, '2017-02-17 00:00:00', 'knielson63', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1293, '5832-6937-3216-6329', 387663868.000000, '2017-04-25 00:00:00', 'ahartas68', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1294, '9218-1566-1068-6049', 399480211.000000, '2017-02-03 00:00:00', 'jkiddey1z', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1295, '8711-8195-4783-1092', 404220924.000000, '2017-05-02 00:00:00', 'rcoomeriz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1296, '3232-3396-8859-4945', 443870316.000000, '2016-10-24 00:00:00', 'scarette86', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1297, '4551-2589-7606-5608', 215832295.000000, '2017-03-24 00:00:00', 'sdevasqn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1298, '0798-4948-4656-4453', 441075579.000000, '2017-02-13 00:00:00', 'zgoodbarrjh', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1299, '8284-5047-3214-2991', 246008556.000000, '2016-10-02 00:00:00', 'hbrearley6v', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1300, '3891-5908-7556-6405', 170753657.000000, '2017-03-23 00:00:00', 'rmeasham3r', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1301, '8950-2285-5040-4032', 316712477.000000, '2016-11-15 00:00:00', 'mfolibr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1302, '5166-2374-5347-4160', 156623819.000000, '2017-01-23 00:00:00', 'pfordycebh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1303, '0495-0274-6737-9516', 296836096.000000, '2016-12-30 00:00:00', 'gcorre48', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1304, '2792-9059-5930-6484', 150296888.000000, '2017-04-14 00:00:00', 'sleisted', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1305, '3897-2818-7764-7654', 389479257.000000, '2017-01-12 00:00:00', 'rimortgn', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1306, '8728-0284-9812-6524', 345191777.000000, '2017-05-25 00:00:00', 'rbodemeaidqy', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1307, '1810-2868-6592-1860', 174302467.000000, '2017-01-01 00:00:00', 'rnevison6o', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1308, '2226-7529-2167-0371', 228577088.000000, '2017-03-08 00:00:00', 'cshobbrook7e', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1309, '2864-4811-5832-3298', 333012611.000000, '2017-07-04 00:00:00', 'mfinckendv', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1310, '0519-8443-6363-4791', 266667150.000000, '2017-05-09 00:00:00', 'arake9y', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1311, '5568-2696-5810-0516', 326616904.000000, '2017-05-27 00:00:00', 'wcattermolel3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1312, '6904-6818-2252-3788', 220228537.000000, '2016-09-30 00:00:00', 'sgrieswood3o', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1313, '8438-2972-3579-8814', 385997104.000000, '2016-10-20 00:00:00', 'tnilesiy', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1314, '2705-5302-1866-9530', 336902039.000000, '2017-03-09 00:00:00', 'kwickey7w', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1315, '8351-7638-6418-0664', 410659787.000000, '2017-06-19 00:00:00', 'tpoter5r', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1316, '2952-6640-6879-5318', 302672972.000000, '2016-11-25 00:00:00', 'igerholdpf', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1317, '9955-6247-5740-6265', 384038960.000000, '2016-10-30 00:00:00', 'cjzak9p', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1318, '1006-8363-7959-5345', 290862912.000000, '2017-01-30 00:00:00', 'mandreasson5f', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1319, '4152-6436-1853-4550', 407150544.000000, '2016-08-23 00:00:00', 'aelgee9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1320, '8192-2341-2023-3195', 237143826.000000, '2017-06-04 00:00:00', 'abaile7n', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1321, '5146-4727-1765-5050', 405094164.000000, '2017-02-10 00:00:00', 'cmarrowcu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1322, '1212-1898-2182-5009', 343159433.000000, '2017-02-01 00:00:00', 'tollerf2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1323, '4469-1115-0179-3752', 290578673.000000, '2016-12-31 00:00:00', 'mparysownajt', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1324, '3578-5937-5577-4200', 409808259.000000, '2017-06-06 00:00:00', 'atullochmu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1325, '7603-4214-2216-1711', 240154420.000000, '2016-12-30 00:00:00', 'wcattermolel3', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1326, '3231-5665-9336-4930', 281520151.000000, '2017-02-05 00:00:00', 'mdadgelq', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1327, '5706-5268-7517-7328', 170865032.000000, '2017-03-04 00:00:00', 'semneymr', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1328, '0500-8267-0385-3204', 232510139.000000, '2016-09-24 00:00:00', 'marnaldyp9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1329, '4041-1655-5923-0729', 409597133.000000, '2016-09-13 00:00:00', 'mfarndaleff', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1330, '8376-7939-9428-9693', 401201623.000000, '2017-07-17 00:00:00', 'ccadejc', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1331, '6669-0305-6209-5818', 241269535.000000, '2017-04-08 00:00:00', 'uledwardm8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1332, '9191-8786-5106-0667', 335559516.000000, '2017-05-23 00:00:00', 'gyuby', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1333, '6949-2008-3748-8577', 227560037.000000, '2016-11-04 00:00:00', 'cglyneq1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1334, '1895-4646-2215-5779', 310191694.000000, '2017-02-01 00:00:00', 'cmckimgg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1335, '3938-0252-3933-7528', 424795189.000000, '2017-06-18 00:00:00', 'mblytha1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1336, '5255-9094-5380-8858', 375405414.000000, '2016-10-14 00:00:00', 'mtenneyn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1337, '7213-3694-2680-3233', 360146297.000000, '2017-05-17 00:00:00', 'gmelmothbg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1338, '5063-8232-6239-0150', 176606110.000000, '2017-02-05 00:00:00', 'psinclarr9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1339, '6914-6780-2252-4531', 368015455.000000, '2017-06-13 00:00:00', 'twenham82', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1340, '9237-4423-9181-6079', 171042575.000000, '2017-07-08 00:00:00', 'kshovelaz', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1341, '6846-6981-4048-7296', 444537151.000000, '2016-09-26 00:00:00', 'mgarlicl9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1342, '8970-0470-8363-0744', 367361483.000000, '2016-12-12 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1343, '1259-1754-5933-9904', 151534255.000000, '2017-07-16 00:00:00', 'tmajorei', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1344, '6736-4528-6431-4990', 269669792.000000, '2017-03-28 00:00:00', 'cschoffler27', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1345, '9603-6566-4780-2484', 389787492.000000, '2016-11-20 00:00:00', 'rsandifordji', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1346, '4303-2080-5179-6157', 343329633.000000, '2017-02-16 00:00:00', 'lamericikd', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1347, '0026-2816-9564-1013', 220609703.000000, '2016-11-29 00:00:00', 'fjirickcl', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1348, '2437-1576-3404-9908', 254589722.000000, '2017-06-01 00:00:00', 'kmckevin38', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1349, '7644-6681-1066-9493', 397208131.000000, '2016-11-19 00:00:00', 'fonolandoi', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1350, '9027-9750-8145-5379', 248901509.000000, '2016-09-08 00:00:00', 'hdalrympleq5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1351, '8029-3357-1321-2734', 415115542.000000, '2017-06-24 00:00:00', 'ko8z', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1352, '8447-8591-4374-9287', 354461460.000000, '2016-10-07 00:00:00', 'nwildsar', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1353, '9956-5857-4936-7706', 357968616.000000, '2016-12-25 00:00:00', 'avellenderms', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1354, '7029-1545-0892-4400', 296296433.000000, '2017-08-04 00:00:00', 'gbaribal7k', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1355, '7668-8112-2077-8420', 287224998.000000, '2016-11-17 00:00:00', 'vwiltshawml', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1356, '4100-6594-6717-1670', 210697593.000000, '2016-08-22 00:00:00', 'gconlaundh6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1357, '0947-0978-6525-5862', 412807920.000000, '2017-01-04 00:00:00', 'ckillingbeckoe', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1358, '5461-3866-0547-6212', 318955398.000000, '2016-09-09 00:00:00', 'ddeemingdo', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1359, '3779-1660-9901-5439', 218021833.000000, '2016-11-19 00:00:00', 'abreenk3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1360, '3202-8785-7610-1620', 225351396.000000, '2016-09-02 00:00:00', 'othorpe8e', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1361, '7634-2860-1941-8213', 389327030.000000, '2017-04-16 00:00:00', 'gsertinda', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1362, '8255-9599-2397-2235', 272374887.000000, '2016-08-11 00:00:00', 'wnicklinsonhn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1363, '2691-9297-6444-7373', 430400406.000000, '2016-11-03 00:00:00', 'daartsenau', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1364, '7553-1142-5366-4335', 332843618.000000, '2017-04-09 00:00:00', 'aaizikovitz9q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1365, '4314-0768-0987-6657', 305240359.000000, '2016-09-28 00:00:00', 'sbossons5h', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1366, '4767-9095-0546-9814', 397888472.000000, '2017-06-02 00:00:00', 'ckillingbeckoe', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1367, '3985-9819-3116-5865', 350403907.000000, '2016-12-21 00:00:00', 'oskipton96', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1368, '7847-2436-8417-7320', 294704525.000000, '2016-12-25 00:00:00', 'cyettsbi', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1369, '5330-5848-7591-3934', 289293368.000000, '2017-07-01 00:00:00', 'mlyddybc', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1370, '5572-5438-7645-6397', 324079050.000000, '2017-05-25 00:00:00', 'oskipton96', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1371, '9333-5118-1529-7984', 430258123.000000, '2017-03-18 00:00:00', 'pohallihanema', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1372, '5759-8945-6212-8937', 419533627.000000, '2017-04-23 00:00:00', 'dmclorinan69', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1373, '8395-3917-3255-9601', 339441569.000000, '2017-03-22 00:00:00', 'csimeonc5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1374, '4131-2373-0165-9478', 268185079.000000, '2016-10-20 00:00:00', 'disoldi9i', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1375, '5033-5983-6056-9695', 374923947.000000, '2017-04-14 00:00:00', 'mpotterypm', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1376, '0960-7222-9969-6257', 389869275.000000, '2016-10-05 00:00:00', 'malsop5p', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1377, '5486-6285-1590-0991', 419326255.000000, '2016-11-18 00:00:00', 'ctommasuzzijs', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1378, '4698-6390-5786-6178', 196129477.000000, '2016-12-09 00:00:00', 'dlockierc6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1379, '4342-2780-7568-5225', 377048734.000000, '2017-05-09 00:00:00', 'estarmorejm', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1380, '7518-6779-3429-9920', 339740994.000000, '2017-01-20 00:00:00', 'tokellyc8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1381, '3088-3945-1440-3580', 179310471.000000, '2017-06-29 00:00:00', 'amackaig8j', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1382, '4408-0595-7155-9372', 392906098.000000, '2017-07-03 00:00:00', 'bdonegand8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1383, '1033-2607-6812-4756', 304915368.000000, '2016-11-24 00:00:00', 'ubavridgeoc', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1384, '3351-8284-2471-0010', 383288224.000000, '2017-03-04 00:00:00', 'lduffilnz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1385, '0634-8834-4770-5595', 198126281.000000, '2017-07-11 00:00:00', 'jofferpj', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1386, '1208-7236-2812-7101', 263622518.000000, '2017-04-02 00:00:00', 'eantico8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1387, '7122-1814-6549-4560', 442585833.000000, '2016-12-04 00:00:00', 'kwyvill52', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1388, '6768-3643-4256-4220', 241067520.000000, '2017-02-27 00:00:00', 'mtrevettlp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1389, '8591-9284-0584-6791', 314700462.000000, '2017-03-17 00:00:00', 'cshobbrook7e', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1390, '6777-1760-8793-1361', 419894110.000000, '2017-05-29 00:00:00', 'tglidden93', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1391, '3523-3487-9241-1570', 342744835.000000, '2017-06-13 00:00:00', 'dskullyg4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1392, '2917-8025-4648-5433', 301507052.000000, '2016-08-17 00:00:00', 'aelizabethoa', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1393, '3322-4897-9107-1728', 251903126.000000, '2017-07-19 00:00:00', 'mguyer1i', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1394, '1715-3197-2111-3732', 223972839.000000, '2017-03-12 00:00:00', 'fjirickcl', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1395, '6097-8025-5355-8835', 393567568.000000, '2017-03-06 00:00:00', 'mdadgelq', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1396, '0608-5823-5376-5827', 287129914.000000, '2017-03-28 00:00:00', 'mtrevettlp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1397, '1715-3747-1720-3476', 317799726.000000, '2017-05-11 00:00:00', 'lduffilnz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1398, '6190-5949-0687-4935', 241265940.000000, '2016-09-06 00:00:00', 'cjagg5o', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1399, '9021-7503-0770-8770', 163306584.000000, '2017-02-04 00:00:00', 'calvaradoos', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1400, '4290-0070-6740-7625', 180541534.000000, '2017-04-23 00:00:00', 'rfrede2c', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1401, '0666-9829-4314-5827', 194674334.000000, '2017-01-26 00:00:00', 'mdimitrescuop', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1402, '9627-0264-8010-2775', 348036102.000000, '2017-02-22 00:00:00', 'gpyke32', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1403, '9663-7399-2659-9823', 203082277.000000, '2017-04-24 00:00:00', 'mwiddecombehw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1404, '3855-6910-5022-2536', 183379775.000000, '2016-10-16 00:00:00', 'vpresswellis', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1405, '4279-6890-8395-1948', 319151913.000000, '2016-09-02 00:00:00', 'fvalentinettird', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1406, '6435-6102-6448-7735', 296108479.000000, '2017-07-22 00:00:00', 'afromantfk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1407, '6311-4328-5738-9003', 169029896.000000, '2017-01-04 00:00:00', 'jbridgett9n', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1408, '2848-2744-0190-5423', 313005333.000000, '2016-12-12 00:00:00', 'ygonsalvo74', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1409, '8873-8169-5351-4597', 293529654.000000, '2016-10-22 00:00:00', 'jlangmaid28', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1410, '4043-0854-4270-8728', 250631261.000000, '2016-11-30 00:00:00', 'lvieyraqp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1411, '8474-4826-4105-1942', 229944399.000000, '2017-01-23 00:00:00', 'hindg3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1412, '1695-8142-0494-1325', 438668175.000000, '2017-04-27 00:00:00', 'ecluelyod', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1413, '8949-2140-6063-1411', 411711688.000000, '2016-09-02 00:00:00', 'tstrainkw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1414, '4054-9689-4325-5539', 243045904.000000, '2016-10-10 00:00:00', 'bgarden8y', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1415, '2555-8595-1981-5035', 429734711.000000, '2017-06-19 00:00:00', 'sgrieswood3o', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1416, '8605-4497-9671-2082', 212436689.000000, '2016-08-30 00:00:00', 'betteridgen6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1417, '5244-2130-6489-3790', 347405103.000000, '2017-07-05 00:00:00', 'mpeltz5v', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1418, '4928-3149-3924-5463', 258606260.000000, '2017-03-28 00:00:00', 'glamswood3y', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1419, '5005-5947-1669-7433', 240465593.000000, '2016-12-28 00:00:00', 'pfordycebh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1420, '3647-6351-8394-2616', 443510514.000000, '2016-09-08 00:00:00', 'tboweringn7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1421, '6891-4271-1973-2374', 193825686.000000, '2017-01-22 00:00:00', 'hindg3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1422, '9450-2942-2446-0134', 278957408.000000, '2016-09-22 00:00:00', 'scaile7p', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1423, '6492-8933-7311-0833', 427794948.000000, '2016-08-11 00:00:00', 'lsemirazfc', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1424, '5466-0802-3043-9209', 269486425.000000, '2017-01-17 00:00:00', 'bbiasi99', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1425, '3000-3455-2371-2202', 200885426.000000, '2016-11-28 00:00:00', 'ckuhleig', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1426, '6129-3758-3370-1064', 351111153.000000, '2017-03-11 00:00:00', 'rliddleqr', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1427, '4951-5075-6890-1921', 280799550.000000, '2017-07-09 00:00:00', 'jallpress6h', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1428, '8808-7037-4636-5458', 155388150.000000, '2016-11-22 00:00:00', 'bmatthewscm', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1429, '8342-8916-6091-0997', 436498743.000000, '2016-09-25 00:00:00', 'gboullin7u', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1430, '4102-3571-7578-9316', 265840331.000000, '2017-06-09 00:00:00', 'agliddon73', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1431, '6007-5744-6350-7012', 200073881.000000, '2017-08-02 00:00:00', 'acripin2v', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1432, '7550-2771-7686-5389', 180873376.000000, '2017-07-25 00:00:00', 'sgymblett5l', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1433, '8624-3519-7073-8889', 190354305.000000, '2017-02-05 00:00:00', 'mjoe53', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1434, '4951-7728-4865-7119', 206401138.000000, '2017-08-05 00:00:00', 'pkirkupf7', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1435, '4210-9603-8763-2613', 258647790.000000, '2017-03-28 00:00:00', 'edealeydp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1436, '0453-2833-3985-5714', 209081057.000000, '2017-05-14 00:00:00', 'mblackwood7y', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1437, '3215-9131-3810-9645', 226685556.000000, '2016-12-01 00:00:00', 'mcrallan2y', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1438, '9437-9631-0215-9569', 153784070.000000, '2016-12-31 00:00:00', 'lcasbolt8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1439, '6111-8936-1243-3669', 318066234.000000, '2016-08-11 00:00:00', 'bmcilraithy', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1440, '4913-8360-5886-2583', 173095669.000000, '2017-07-15 00:00:00', 'cjzak9p', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1441, '1630-2763-2918-1826', 215226089.000000, '2016-11-20 00:00:00', 'jchildrenac', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1442, '0467-4180-3844-5016', 377634181.000000, '2017-03-14 00:00:00', 'cfishpond2a', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1443, '6711-5787-2026-3049', 393577453.000000, '2016-09-14 00:00:00', 'dlongridgehp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1444, '8016-7570-0156-5732', 174587339.000000, '2017-06-06 00:00:00', 'akeerl9o', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1445, '5312-6857-8329-4307', 443947616.000000, '2016-11-23 00:00:00', 'ecarlesiib', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1446, '8492-1601-9003-0722', 417956534.000000, '2016-08-20 00:00:00', 'sglantonq3', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1447, '1850-5689-4698-5360', 162725122.000000, '2017-04-28 00:00:00', 'hbeesn3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1448, '5549-7201-3406-2052', 232424006.000000, '2017-01-07 00:00:00', 'ufowler46', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1449, '2145-0817-1806-5619', 274705380.000000, '2017-02-14 00:00:00', 'nmidfordhx', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1450, '3386-4862-5982-2134', 339211746.000000, '2016-10-24 00:00:00', 'jchildrenac', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1451, '8133-2840-6789-4226', 249006212.000000, '2017-01-15 00:00:00', 'mjupeen', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1452, '4207-6401-0561-6908', 215368721.000000, '2016-08-06 00:00:00', 'eantico8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1453, '0918-4472-2848-7283', 311764924.000000, '2017-05-10 00:00:00', 'ayielding6m', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1454, '1747-5102-2907-6287', 201478950.000000, '2017-02-06 00:00:00', 'mtrevettlp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1455, '0409-6333-1242-5641', 309199078.000000, '2016-10-05 00:00:00', 'msarton2d', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1456, '2301-0035-4173-7602', 349722795.000000, '2016-09-05 00:00:00', 'tscollandki', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1457, '0972-2060-7570-4742', 433025938.000000, '2017-05-02 00:00:00', 'mdadgelq', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1458, '8400-7278-4743-0412', 170815900.000000, '2016-12-21 00:00:00', 'trizzinik9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1459, '1630-0325-3078-1771', 432853535.000000, '2016-11-10 00:00:00', 'kwickey7w', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1460, '9762-0319-9292-3843', 250462875.000000, '2017-02-18 00:00:00', 'kdaubney1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1461, '3055-9395-0551-1743', 185386908.000000, '2017-07-14 00:00:00', 'sgrieswood3o', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1462, '3690-3934-5226-0835', 357616505.000000, '2017-07-25 00:00:00', 'aworsfieldfv', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1463, '6618-0714-7209-2612', 229262426.000000, '2017-06-22 00:00:00', 'kaspdenas', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1464, '8312-8004-6508-8521', 272690165.000000, '2016-09-20 00:00:00', 'standerkv', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1465, '6475-6514-2453-4835', 189764716.000000, '2017-03-16 00:00:00', 'twenham82', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1466, '8378-6768-8364-3911', 365807985.000000, '2017-04-01 00:00:00', 'tokellyc8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1467, '4005-4766-2723-3197', 354960983.000000, '2016-09-02 00:00:00', 'uhuckinlf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1468, '0687-8276-6997-1825', 172324516.000000, '2016-10-16 00:00:00', 'miviedz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1469, '7990-8986-5243-0174', 339568523.000000, '2017-01-18 00:00:00', 'mcoucheaq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1470, '6362-1048-2724-2482', 312565104.000000, '2016-11-29 00:00:00', 'rmancejw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1471, '1103-8690-6162-9912', 179011598.000000, '2017-02-05 00:00:00', 'abengallke', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1472, '9312-3571-8136-5150', 430574475.000000, '2016-09-29 00:00:00', 'jdomnickra', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1473, '2541-3883-4415-5470', 213441919.000000, '2017-05-16 00:00:00', 'mpochethh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1474, '1155-5855-4355-6453', 272665075.000000, '2017-02-26 00:00:00', 'kgosselin6e', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1475, '0481-3816-5327-8449', 281910599.000000, '2017-03-10 00:00:00', 'hjedraszek23', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1476, '7768-6079-3106-5111', 332700448.000000, '2017-02-23 00:00:00', 'acripin2v', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1477, '9976-0588-1601-7673', 415413124.000000, '2016-11-17 00:00:00', 'bguppeyak', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1478, '9463-7248-4089-1277', 332616184.000000, '2017-07-14 00:00:00', 'hchavez2x', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1479, '5537-9720-1139-0893', 359703811.000000, '2017-06-22 00:00:00', 'ckillingbeckoe', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1480, '4478-6872-9766-2388', 293702424.000000, '2017-01-12 00:00:00', 'tsidnell2l', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1481, '5737-9930-3751-6329', 398871105.000000, '2017-01-11 00:00:00', 'ssouthcoate4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1482, '4465-3058-5886-7856', 337854364.000000, '2017-05-11 00:00:00', 'visaksond', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1483, '8745-2834-9122-8299', 412444459.000000, '2016-09-13 00:00:00', 'bforsdicke8v', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1484, '3562-0267-9135-6995', 330939415.000000, '2017-03-24 00:00:00', 'rhaineyi7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1485, '5830-2732-8025-4631', 306774635.000000, '2017-03-12 00:00:00', 'hspittlesr2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1486, '7306-9992-1336-8948', 165126732.000000, '2017-06-23 00:00:00', 'lbevisa3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1487, '1082-9900-0565-9255', 206316917.000000, '2017-02-23 00:00:00', 'reilersm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1488, '8466-9796-9588-7753', 256827494.000000, '2016-09-02 00:00:00', 'aphilipp4l', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1489, '0356-9831-7390-6579', 384850909.000000, '2016-08-13 00:00:00', 'pmcallev', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1490, '8468-1656-5592-5265', 234052058.000000, '2016-12-31 00:00:00', 'kleander3d', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1491, '9213-9472-8334-0889', 360827454.000000, '2016-10-20 00:00:00', 'mdudnypi', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1492, '8721-1513-2509-7767', 214404336.000000, '2016-09-30 00:00:00', 'emcilwreathj8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1493, '3546-4779-2181-9597', 413742112.000000, '2017-06-29 00:00:00', 'cantat9d', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1494, '4568-2630-8285-9226', 345547821.000000, '2016-10-29 00:00:00', 'bemneybq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1495, '8682-7001-7740-8714', 249993683.000000, '2017-05-22 00:00:00', 'mskillinggu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1496, '0403-3112-9590-3201', 340640012.000000, '2016-11-04 00:00:00', 'gdumingos80', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1497, '2018-6394-5751-8840', 278394068.000000, '2017-05-31 00:00:00', 'lsmoutena7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1498, '7572-5956-2301-9837', 369942784.000000, '2017-04-16 00:00:00', 'lcasbolt8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1499, '2138-4325-5167-1782', 436566560.000000, '2016-10-18 00:00:00', 'dolahy12', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1500, '5844-8348-1804-8665', 303569627.000000, '2017-02-13 00:00:00', 'chaylor4m', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1501, '4640-0341-9387-5781', 395409782.000000, '2017-02-17 00:00:00', 'levittsrk', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1502, '1630-2511-2937-7299', 240149353.000000, '2016-08-13 00:00:00', 'chaylor4m', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1503, '6592-7866-3024-5314', 326096199.000000, '2016-12-25 00:00:00', 'aloisib4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1504, '1475-4858-1691-5789', 266252038.000000, '2016-11-23 00:00:00', 'rdamantcw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1505, '3992-3343-8699-1754', 266507555.000000, '2017-02-15 00:00:00', 'gtrenholmekm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1506, '9065-8351-4489-8687', 341283690.000000, '2017-02-13 00:00:00', 'uyerrallmj', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1507, '2928-4331-8647-0560', 280431140.000000, '2016-09-08 00:00:00', 'rsandifordji', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1508, '7173-6253-2005-9312', 198183234.000000, '2017-08-04 00:00:00', 'mroadse6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1509, '6939-8463-2899-6921', 385430156.000000, '2017-02-05 00:00:00', 'santoninkp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1510, '1215-0877-5497-4162', 397878257.000000, '2016-09-08 00:00:00', 'mcornell7j', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1511, '2632-3183-7851-1820', 239399021.000000, '2017-08-03 00:00:00', 'standerkv', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1512, '9935-9879-2260-2925', 430051063.000000, '2016-09-05 00:00:00', 'mparysownajt', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1513, '9964-7808-5543-3283', 201229872.000000, '2017-03-03 00:00:00', 'mhinzernk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1514, '1029-9774-2970-1730', 286325193.000000, '2017-05-13 00:00:00', 'ecockramae', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1515, '4542-3132-7580-5698', 445904895.000000, '2017-07-28 00:00:00', 'cmarrowcu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1516, '5476-9906-2825-9952', 414543960.000000, '2016-10-05 00:00:00', 'gcastellucci8i', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1517, '3730-3787-8629-3917', 299588120.000000, '2016-09-18 00:00:00', 'lwhetnallcb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1518, '1178-7900-5881-6552', 369476805.000000, '2017-05-05 00:00:00', 'uledwardm8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1519, '5318-9901-9863-4382', 394743840.000000, '2017-07-13 00:00:00', 'jmackettn2', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1520, '0350-1117-8856-7980', 251179962.000000, '2017-02-09 00:00:00', 'rbowllerek', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1521, '6583-2282-3212-0467', 272537260.000000, '2016-09-26 00:00:00', 'gmelmothbg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1522, '1541-4277-0660-4459', 349153051.000000, '2016-12-09 00:00:00', 'smantlm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1523, '9590-2625-2150-7258', 210426538.000000, '2017-07-12 00:00:00', 'sthebeaudbp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1524, '0636-0754-0405-3314', 449094665.000000, '2016-09-15 00:00:00', 'talamaa', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1525, '2363-7005-2893-4182', 215626147.000000, '2017-08-03 00:00:00', 'sleatonfo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1526, '1683-9992-4718-7113', 226837403.000000, '2016-10-15 00:00:00', 'gkretschmerat', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1527, '5095-6341-6973-5274', 327570757.000000, '2017-04-04 00:00:00', 'oongin5x', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1528, '9181-1189-4069-8436', 157311680.000000, '2016-09-19 00:00:00', 'odebowb7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1529, '1866-9428-1104-6886', 218600010.000000, '2017-01-20 00:00:00', 'fmathiassen7l', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1530, '8278-7710-7311-4788', 449376055.000000, '2016-10-04 00:00:00', 'lbloxland21', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1531, '4064-9491-1791-9866', 409145882.000000, '2016-12-19 00:00:00', 'lhurley5a', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1532, '0117-2729-2666-4999', 287206663.000000, '2016-08-31 00:00:00', 'bguppeyak', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1533, '9455-7519-9184-1316', 383785992.000000, '2017-07-05 00:00:00', 'lwinfredn9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1534, '4489-2174-0669-7685', 418550277.000000, '2017-04-21 00:00:00', 'gbroomheaddy', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1535, '6760-5797-6026-8236', 356562550.000000, '2017-03-27 00:00:00', 'kwickey7w', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1536, '0475-0347-5867-3706', 278482961.000000, '2017-01-31 00:00:00', 'randover8p', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1537, '1164-3535-1779-9752', 194064036.000000, '2017-04-10 00:00:00', 'sschwandermannm3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1538, '8918-2649-5470-5706', 189519021.000000, '2017-02-05 00:00:00', 'cnowakowskiiw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1539, '6499-7973-8172-6081', 174702254.000000, '2016-09-02 00:00:00', 'cbrabon45', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1540, '8466-6269-4466-4874', 323129132.000000, '2017-04-23 00:00:00', 'ejacmar5t', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1541, '9999-8370-6668-7190', 383376352.000000, '2016-10-14 00:00:00', 'adonlonm5', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1542, '7116-7842-3370-2242', 383329768.000000, '2016-09-30 00:00:00', 'asmithemanmd', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1543, '7761-2171-6893-8685', 230494079.000000, '2017-02-09 00:00:00', 'bmccloyl0', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1544, '7486-5639-1437-3118', 224914247.000000, '2016-10-19 00:00:00', 'lgiamoec', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1545, '3407-5270-2479-7393', 305314887.000000, '2017-07-12 00:00:00', 'avedeniktov78', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1546, '2079-4572-9595-5154', 337127304.000000, '2017-04-13 00:00:00', 'mmussettinie0', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1547, '6758-7942-1548-0121', 247268876.000000, '2017-03-21 00:00:00', 'rwhyliefg', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1548, '9591-3296-4863-4542', 223901285.000000, '2017-06-01 00:00:00', 'acanedo5u', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1549, '1189-7024-1496-1936', 402733392.000000, '2017-01-02 00:00:00', 'daartsenau', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1550, '2632-8850-8767-6806', 202434571.000000, '2016-10-26 00:00:00', 'tbaptistare', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1551, '9505-0277-8346-3969', 229758859.000000, '2017-01-08 00:00:00', 'aphillips', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1552, '2139-8397-7084-4093', 447761836.000000, '2017-02-11 00:00:00', 'jnicklen30', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1553, '8496-8115-5596-9722', 197848861.000000, '2017-01-08 00:00:00', 'bnibloe1o', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1554, '1078-8795-8240-6760', 217442807.000000, '2016-12-29 00:00:00', 'visaksond', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1555, '6447-3132-2386-3059', 335690357.000000, '2017-03-06 00:00:00', 'fbroome5i', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1556, '4868-7136-8392-3176', 387977607.000000, '2016-11-29 00:00:00', 'mgarlicl9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1557, '3803-6035-3793-4001', 441193693.000000, '2016-12-19 00:00:00', 'jlangmaid28', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1558, '4491-5667-1554-9630', 151028549.000000, '2017-06-17 00:00:00', 'nwalsh6l', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1559, '0268-5280-7709-0786', 337891489.000000, '2017-06-02 00:00:00', 'cnevinsna', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1560, '8949-3946-3107-0179', 253647865.000000, '2017-06-22 00:00:00', 'tenzleymz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1561, '6121-8028-2625-4222', 219357520.000000, '2017-06-09 00:00:00', 'gtorransqz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1562, '8745-0201-1661-2523', 399347532.000000, '2017-03-23 00:00:00', 'ltomeoik', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1563, '4935-1821-8202-2968', 441042321.000000, '2016-12-25 00:00:00', 'xharlinc7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1564, '6746-5524-6238-5271', 239065141.000000, '2017-05-28 00:00:00', 'hkilbourneoo', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1565, '3526-8802-4949-4634', 440030348.000000, '2017-01-01 00:00:00', 'wrowenaew', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1566, '7664-2611-7081-6632', 169783675.000000, '2017-01-20 00:00:00', 'mbartosch7h', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1567, '6541-5717-5729-7113', 272575093.000000, '2017-01-23 00:00:00', 'gcattoncr', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1568, '3372-1461-3357-0143', 337898649.000000, '2017-04-01 00:00:00', 'cgrichukhanovo2', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1569, '9689-1520-0552-2257', 340522557.000000, '2016-12-30 00:00:00', 'mjancyor', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1570, '2802-2131-5201-0271', 417504741.000000, '2017-06-21 00:00:00', 'csetfordls', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1571, '5206-5934-1915-3021', 209126918.000000, '2017-06-18 00:00:00', 'jtoulamainpo', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1572, '6491-2184-3317-1931', 275429480.000000, '2017-05-03 00:00:00', 'aloisib4', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1573, '6635-4746-9618-9316', 347923309.000000, '2016-12-29 00:00:00', 'lbloxland21', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1574, '3368-0816-3360-9187', 236825483.000000, '2016-11-03 00:00:00', 'hindg3', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1575, '5428-5398-1935-2463', 280495688.000000, '2017-01-25 00:00:00', 'fkenrickj1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1576, '2650-5157-3672-6578', 359751988.000000, '2017-02-07 00:00:00', 'bbastinh7', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1577, '4192-8466-3559-0834', 326489492.000000, '2016-10-10 00:00:00', 'rbriars95', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1578, '8203-9351-1310-1235', 389105528.000000, '2016-10-30 00:00:00', 'qtilll6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1579, '9400-6128-0621-5409', 294041908.000000, '2016-12-16 00:00:00', 'rcummine9c', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1580, '4119-6950-3561-4992', 260626020.000000, '2017-04-03 00:00:00', 'fjirickcl', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1581, '0346-9608-7387-6327', 165036686.000000, '2017-05-27 00:00:00', 'bnibloe1o', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1582, '5622-1722-7571-8255', 434050087.000000, '2017-02-12 00:00:00', 'bmcilraithy', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1583, '8959-5852-1379-0192', 442371986.000000, '2017-03-21 00:00:00', 'psloraes', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1584, '6557-7799-9961-8218', 430449326.000000, '2017-03-12 00:00:00', 'bnajerad6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1585, '0514-4787-8982-4300', 197033570.000000, '2017-02-19 00:00:00', 'mtorriem1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1586, '0140-4923-2389-0727', 350122931.000000, '2017-07-05 00:00:00', 'jphysick33', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1587, '3780-0383-1667-6535', 216049110.000000, '2017-04-22 00:00:00', 'sbossons5h', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1588, '1986-8035-6874-7565', 395743968.000000, '2016-10-21 00:00:00', 'gmckuelk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1589, '0820-4587-6824-7985', 229958462.000000, '2016-11-12 00:00:00', 'mvelarealoy', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1590, '4452-2795-2853-9523', 396606889.000000, '2016-11-04 00:00:00', 'wmcduffie1j', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1591, '7401-6719-2903-4065', 185039081.000000, '2017-07-09 00:00:00', 'hshewonho', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1592, '9363-1099-8826-5566', 304132703.000000, '2016-11-18 00:00:00', 'aworsfieldfv', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1593, '1123-4560-6785-9543', 319141696.000000, '2017-08-05 00:00:00', 'ccurbishley4p', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1594, '5551-1019-1170-6548', 206097632.000000, '2017-02-01 00:00:00', 'pdoig70', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1595, '6313-3080-5678-3858', 260178153.000000, '2017-06-26 00:00:00', 'apenricenh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1596, '4710-8990-0069-3222', 249255376.000000, '2017-05-19 00:00:00', 'lugolini77', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1597, '1363-2180-8920-1867', 330867833.000000, '2016-12-22 00:00:00', 'ukernockecx', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1598, '0181-2541-5255-2584', 260291976.000000, '2016-11-20 00:00:00', 'dhearlefh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1599, '7665-4361-2051-0234', 246000131.000000, '2016-09-01 00:00:00', 'bbattermy', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1600, '3671-1051-5487-3782', 194337659.000000, '2016-08-01 00:00:00', 'mcoucheaq', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1601, '6424-8071-9108-4502', 172274054.000000, '2017-02-08 00:00:00', 'kdecourcyi9', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1602, '7820-4469-0702-7629', 233990990.000000, '2017-07-25 00:00:00', 'cfiennes1t', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1603, '8208-5994-1776-8085', 408467139.000000, '2016-11-09 00:00:00', 'nspieghtnt', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1604, '4981-4577-3614-8588', 247600791.000000, '2017-07-08 00:00:00', 'gtuhyr7', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1605, '7328-1152-9776-2856', 291220191.000000, '2016-11-21 00:00:00', 'tbullivantic', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1606, '5477-1421-8772-8324', 164067898.000000, '2017-01-03 00:00:00', 'asiebertpz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1607, '9319-6402-6367-9643', 397314135.000000, '2016-10-27 00:00:00', 'fbuttle36', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1608, '0692-8676-7680-5833', 306976639.000000, '2017-02-11 00:00:00', 'sgilliattav', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1609, '6853-1210-7083-5530', 237595626.000000, '2017-03-23 00:00:00', 'cmeechou', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1610, '2107-2630-0013-7168', 317275595.000000, '2016-09-12 00:00:00', 'jquinanei2', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1611, '2530-4884-4726-8684', 405066651.000000, '2017-05-16 00:00:00', 'dtowers3a', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1612, '9153-0285-9063-5908', 159934934.000000, '2016-10-03 00:00:00', 'vkenealyqx', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1613, '0074-8367-8071-1220', 311933769.000000, '2017-08-01 00:00:00', 'bmccunn2f', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1614, '0081-7911-8197-5581', 269896411.000000, '2017-05-29 00:00:00', 'tbullivantic', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1615, '2893-6865-7692-8052', 261029485.000000, '2016-09-04 00:00:00', 'imartinez98', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1616, '8730-6745-7677-0461', 335930779.000000, '2016-11-26 00:00:00', 'mraittp5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1617, '1405-4442-6573-5897', 205764221.000000, '2016-10-23 00:00:00', 'ecaress5q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1618, '1648-0781-3078-1877', 204695808.000000, '2016-09-07 00:00:00', 'hdaffornem0', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1619, '8309-1029-1985-4355', 278482296.000000, '2017-05-26 00:00:00', 'ahealeasnr', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1620, '2221-0754-3973-1051', 367877364.000000, '2016-09-30 00:00:00', 'ashannahand0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1621, '4785-7858-5902-0580', 394059331.000000, '2017-07-22 00:00:00', 'tsnodinge8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1622, '9452-0825-2091-3906', 205414199.000000, '2017-04-19 00:00:00', 'akeerl9o', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1623, '7790-6384-6955-0766', 172514581.000000, '2017-06-28 00:00:00', 'ckillingbeckoe', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1624, '2329-7925-9726-5030', 336878992.000000, '2017-06-22 00:00:00', 'omccardlef5', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1625, '6642-6674-6250-1202', 361336204.000000, '2017-01-16 00:00:00', 'lmccalisterk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1626, '3925-5240-3610-2141', 378840026.000000, '2017-06-22 00:00:00', 'hmalcherli', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1627, '6415-4192-3179-9426', 314827799.000000, '2016-10-03 00:00:00', 'meastmondo5', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1628, '5952-2699-9699-3113', 178473256.000000, '2016-11-07 00:00:00', 'levittsrk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1629, '0841-2249-8886-5338', 426209016.000000, '2017-04-26 00:00:00', 'po3n', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1630, '3304-1266-4460-0809', 231707599.000000, '2016-10-14 00:00:00', 'egoodding1k', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1631, '7591-2485-8429-7497', 311479957.000000, '2016-09-29 00:00:00', 'jchapple2e', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1632, '7872-2526-6619-2504', 304441896.000000, '2016-10-09 00:00:00', 'mblytha1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1633, '8208-5565-5813-1453', 277475473.000000, '2016-09-03 00:00:00', 'arichiek6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1634, '6761-5503-3356-1971', 369954649.000000, '2017-05-28 00:00:00', 'gportmt', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1635, '9446-5312-0194-9512', 243724146.000000, '2016-12-19 00:00:00', 'abeneditopx', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1636, '4593-9532-3041-7011', 366213421.000000, '2016-08-07 00:00:00', 'gtuhyr7', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1637, '1373-6024-9204-8582', 427887788.000000, '2017-06-29 00:00:00', 'gsurman8t', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1638, '9564-8786-5763-0311', 312196341.000000, '2016-12-14 00:00:00', 'mtrevettlp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1639, '6889-0041-6232-5724', 317895790.000000, '2016-12-28 00:00:00', 'dcahnhm', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1640, '4377-0106-3176-8044', 390750774.000000, '2017-02-12 00:00:00', 'lduffilnz', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1641, '0093-0717-7855-8621', 229217601.000000, '2017-02-03 00:00:00', 'dhyettme', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1642, '5498-8953-4099-5133', 261134854.000000, '2016-10-07 00:00:00', 'dhearlefh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1643, '4159-0519-3146-3812', 430354179.000000, '2017-04-04 00:00:00', 'hdalrympleq5', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1644, '2177-9204-5855-2340', 176094134.000000, '2017-02-06 00:00:00', 'ecoghlinpw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1645, '4408-7236-9916-1891', 201603775.000000, '2017-03-09 00:00:00', 'eobroganegi', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1646, '0822-7068-9243-8891', 305223126.000000, '2017-07-23 00:00:00', 'dmontegs', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1647, '1780-2902-1963-8625', 415456018.000000, '2017-04-18 00:00:00', 'emarien57', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1648, '9704-9929-7178-8103', 238687627.000000, '2016-09-02 00:00:00', 'bhasardgb', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1649, '1778-8428-8990-5968', 427533692.000000, '2017-02-16 00:00:00', 'lgiamoec', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1650, '0177-7899-6206-8106', 160160513.000000, '2016-11-03 00:00:00', 'eantico8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1651, '9899-9870-2438-3478', 377860979.000000, '2016-10-17 00:00:00', 'amckearnena5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1652, '4170-9568-1904-9980', 383965756.000000, '2016-12-27 00:00:00', 'lcantrilleq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1653, '9827-9591-6662-0112', 260745459.000000, '2016-08-10 00:00:00', 'bhorlick9u', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1654, '9409-0563-8504-7287', 384847823.000000, '2016-09-27 00:00:00', 'ddeemingdo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1655, '9811-1722-5045-0670', 224047368.000000, '2017-01-30 00:00:00', 'scoultl4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1656, '9350-0086-1238-0376', 158881274.000000, '2017-02-13 00:00:00', 'hbetancourt6p', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1657, '3605-7164-4531-3983', 438018156.000000, '2016-12-04 00:00:00', 'sblomfieldeo', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1658, '2387-4116-3699-0044', 249441655.000000, '2017-06-19 00:00:00', 'rpetracchiot', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1659, '4327-3699-3991-5248', 347748280.000000, '2017-06-10 00:00:00', 'sgrinstedfd', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1660, '8057-8052-0967-7029', 164214823.000000, '2016-09-12 00:00:00', 'lduffilnz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1661, '2125-2796-8386-1777', 181900696.000000, '2017-06-05 00:00:00', 'hculprf', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1662, '7111-5132-7995-5089', 284386327.000000, '2017-02-20 00:00:00', 'mpotterypm', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1663, '4305-2519-0729-1255', 250101782.000000, '2017-02-02 00:00:00', 'mpotterypm', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1664, '2819-7576-2967-7617', 215052015.000000, '2017-04-15 00:00:00', 'dhyettme', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1665, '7600-5534-7912-7650', 150783300.000000, '2016-11-23 00:00:00', 'rnevison6o', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1666, '0031-0825-4207-7451', 282883496.000000, '2017-04-22 00:00:00', 'gcaneg5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1667, '9494-1375-9599-2451', 320024310.000000, '2017-07-27 00:00:00', 'cfoyston72', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1668, '7785-2013-9754-1083', 154388827.000000, '2017-02-28 00:00:00', 'tsodaa0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1669, '6690-3842-6103-9519', 428360932.000000, '2016-11-11 00:00:00', 'khaken7m', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1670, '2639-9433-6813-5967', 424840612.000000, '2017-06-21 00:00:00', 'pprobyncg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1671, '6646-0588-6217-9747', 373856720.000000, '2016-12-20 00:00:00', 'trizzinik9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1672, '6549-6805-4081-8635', 151563694.000000, '2017-02-02 00:00:00', 'gcorre48', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1673, '8004-0166-8784-4683', 297597952.000000, '2017-07-27 00:00:00', 'mlavies8n', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1674, '8881-4291-1393-9206', 277119651.000000, '2017-05-15 00:00:00', 'tjasperqf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1675, '1628-4469-4254-4255', 235207729.000000, '2017-07-19 00:00:00', 'tsnodinge8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1676, '8552-0405-6197-9901', 325187078.000000, '2016-11-10 00:00:00', 'twenham82', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1677, '9883-5961-6517-4010', 375410907.000000, '2016-11-22 00:00:00', 'mmonksfieldlj', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1678, '3084-3732-4361-0086', 201708938.000000, '2016-10-01 00:00:00', 'wshivlinr3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1679, '0746-0674-7223-5619', 359066216.000000, '2017-01-10 00:00:00', 'arichiek6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1680, '2280-1779-0471-5318', 302601613.000000, '2017-02-01 00:00:00', 'glegoode1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1681, '5545-1357-9636-3169', 250850113.000000, '2017-03-27 00:00:00', 'mlavies8n', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1682, '3583-8213-4143-9711', 277069656.000000, '2017-02-09 00:00:00', 'jduigenano3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1683, '5081-7006-2463-0217', 354610643.000000, '2016-08-07 00:00:00', 'cantat9d', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1684, '0625-5789-0933-9728', 328055268.000000, '2017-01-16 00:00:00', 'prennelsfu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1685, '0140-2787-6477-4524', 355148294.000000, '2017-06-03 00:00:00', 'standerkv', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1686, '4821-3301-7746-1349', 296016124.000000, '2016-08-04 00:00:00', 'ematticcinq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1687, '9606-1585-2060-8079', 335655774.000000, '2016-12-06 00:00:00', 'mdimitrescuop', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1688, '5467-3923-1765-7151', 367316237.000000, '2017-08-06 00:00:00', 'talamaa', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1689, '0097-7698-8413-7348', 176206690.000000, '2017-06-08 00:00:00', 'bdonegand8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1690, '1508-2064-2026-7610', 350753152.000000, '2016-11-07 00:00:00', 'nreidem4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1691, '0276-7149-2926-4746', 431028560.000000, '2017-05-16 00:00:00', 'miviedz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1692, '5345-1932-3298-5325', 258929600.000000, '2017-06-20 00:00:00', 'ddjokovicnw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1693, '6387-3084-2819-5638', 188306112.000000, '2016-12-31 00:00:00', 'mzmitruk1r', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1694, '2374-2534-7359-2444', 359057716.000000, '2016-08-06 00:00:00', 'mjuschkemq', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1695, '8263-6894-0909-0911', 354312963.000000, '2017-02-14 00:00:00', 'uborithr', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1696, '3376-3270-3265-3518', 230232762.000000, '2016-12-24 00:00:00', 'koulettp2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1697, '6941-1137-1293-6653', 420770239.000000, '2017-06-07 00:00:00', 'tbaptistare', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1698, '0075-6185-1037-6321', 240709076.000000, '2016-11-04 00:00:00', 'sleatonfo', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1699, '1100-7332-6663-8295', 182885682.000000, '2017-06-22 00:00:00', 'cokenden75', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1700, '8580-4430-7584-2750', 441995213.000000, '2017-07-19 00:00:00', 'frylancel7', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1701, '9392-5951-1261-6862', 242048786.000000, '2016-09-03 00:00:00', 'mschabenk7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1702, '6208-3887-9872-0419', 353991455.000000, '2016-09-11 00:00:00', 'whatliffedm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1703, '5998-1286-0435-2887', 346023347.000000, '2017-01-22 00:00:00', 'rmichelov', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1704, '8722-1029-6046-2103', 318929301.000000, '2016-10-05 00:00:00', 'mskillinggu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1705, '6876-3354-5583-1458', 290106783.000000, '2017-06-08 00:00:00', 'plohoaro7', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1706, '3915-5119-8398-0697', 174520384.000000, '2016-09-30 00:00:00', 'rsibthorpgh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1707, '6879-9953-6602-9061', 208436329.000000, '2016-11-07 00:00:00', 'jsarginth2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1708, '2998-6007-0135-7091', 163472398.000000, '2017-07-12 00:00:00', 'lpetrello1l', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1709, '7016-8978-9924-1613', 255028490.000000, '2017-01-26 00:00:00', 'rsandifordji', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1710, '3535-2449-5558-7697', 396771676.000000, '2017-04-01 00:00:00', 'mdanielsencc', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1711, '8000-2272-1003-6653', 273125256.000000, '2017-08-02 00:00:00', 'dskullyg4', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1712, '0941-9567-9911-0938', 397318965.000000, '2017-01-11 00:00:00', 'cismirnioglou2p', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1713, '9865-7398-8744-4357', 297377117.000000, '2017-03-26 00:00:00', 'tsiggersrj', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1714, '4348-8697-9298-2108', 403814485.000000, '2017-01-13 00:00:00', 'cgoning6q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1715, '6953-0000-0012-2654', 289932491.000000, '2017-03-31 00:00:00', 'tboweringn7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1716, '9372-1718-0849-8844', 447375242.000000, '2017-03-16 00:00:00', 'eantico8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1717, '5374-2352-9131-4756', 433557171.000000, '2017-03-05 00:00:00', 'cmeechou', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1718, '4490-3980-7238-8700', 335149876.000000, '2017-01-22 00:00:00', 'rcalcraftn4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1719, '4759-7971-8874-1491', 253978776.000000, '2017-06-15 00:00:00', 'afromantfk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1720, '5414-2120-4147-4860', 339247027.000000, '2017-03-14 00:00:00', 'gdanfortho0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1721, '6771-5490-2874-7421', 384775442.000000, '2017-06-09 00:00:00', 'tstrainkw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1722, '6130-3140-1930-7167', 336037024.000000, '2016-12-28 00:00:00', 'hmalcherli', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1723, '7671-7317-0267-7964', 227202905.000000, '2017-03-23 00:00:00', 'fcorkelgq', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1724, '1679-2509-6968-7377', 165564921.000000, '2017-01-03 00:00:00', 'hdalrympleq5', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1725, '7366-7385-3876-8415', 230426145.000000, '2016-11-09 00:00:00', 'marnaldyp9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1726, '6735-0858-7744-7994', 443881219.000000, '2016-12-15 00:00:00', 'ioharaqh', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1727, '9047-7506-0162-0489', 185433942.000000, '2017-04-29 00:00:00', 'cusborn1m', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1728, '7881-2895-3447-1545', 204346390.000000, '2016-11-14 00:00:00', 'hcordobesfi', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1729, '1244-3751-3519-7016', 178294902.000000, '2016-08-08 00:00:00', 'nhugeninjx', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1730, '7800-5498-7867-5837', 365107960.000000, '2017-03-20 00:00:00', 'psinclarr9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1731, '1218-5597-4263-9081', 418948584.000000, '2017-01-28 00:00:00', 'mcrallan2y', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1732, '5123-5612-7316-1987', 378000934.000000, '2016-10-02 00:00:00', 'mhinzernk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1733, '0605-9991-1349-8896', 405490546.000000, '2017-01-04 00:00:00', 'sleatonfo', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1734, '6024-2414-7844-5037', 340929162.000000, '2016-11-01 00:00:00', 'jtoulamainpo', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1735, '3564-5733-3113-4933', 274623348.000000, '2017-06-20 00:00:00', 'bemneybq', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1736, '3163-6133-3780-5137', 241013085.000000, '2016-12-23 00:00:00', 'bmatousek6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1737, '7629-4189-1211-5218', 432730380.000000, '2016-09-13 00:00:00', 'tnajerapk', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1738, '2370-4863-9564-5049', 300841424.000000, '2016-10-06 00:00:00', 'etubblepb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1739, '6703-6438-5781-3618', 314347412.000000, '2017-01-27 00:00:00', 'vwiltshawml', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1740, '9512-2858-0859-3287', 154844436.000000, '2016-09-04 00:00:00', 'cfoxcroft91', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1741, '7168-3838-8848-0614', 210003522.000000, '2017-02-26 00:00:00', 'tnilesiy', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1742, '2425-7395-8704-0178', 329819382.000000, '2017-07-23 00:00:00', 'mmayoralct', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1743, '3118-9370-9608-0660', 292076602.000000, '2016-10-31 00:00:00', 'hdahlerbf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1744, '0714-1131-7491-7867', 414642295.000000, '2017-07-30 00:00:00', 'pswane61', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1745, '3787-9057-2673-4768', 158124687.000000, '2016-08-29 00:00:00', 'mfolibr', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1746, '6926-2835-3378-2241', 274048376.000000, '2016-09-21 00:00:00', 'lbrisbane9x', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1747, '6927-8165-6542-7138', 399180475.000000, '2016-11-02 00:00:00', 'bwitseyo', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1748, '6288-7006-5475-6661', 396164040.000000, '2017-07-13 00:00:00', 'fvalentinettird', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1749, '1832-9622-2825-4224', 418847422.000000, '2017-06-17 00:00:00', 'rnadingf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1750, '1232-4421-2594-5281', 446912997.000000, '2017-02-03 00:00:00', 'tnaton7s', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1751, '1486-3459-0435-3155', 173942251.000000, '2017-07-21 00:00:00', 'mantunez6a', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1752, '8910-8488-8040-7169', 389253591.000000, '2017-07-26 00:00:00', 'bhuzzeyns', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1753, '6243-5359-5834-3643', 441234514.000000, '2016-08-05 00:00:00', 'mschabenk7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1754, '3349-8388-9044-8651', 151169241.000000, '2017-08-04 00:00:00', 'dbever14', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1755, '3030-5344-0883-5346', 192120162.000000, '2017-01-17 00:00:00', 'sbossons5h', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1756, '3652-8402-2084-3744', 235677616.000000, '2016-11-17 00:00:00', 'mjuschkemq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1757, '1283-8610-4212-9730', 189015979.000000, '2016-10-08 00:00:00', 'lzanettohs', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1758, '9634-2056-2795-7015', 368363004.000000, '2016-08-02 00:00:00', 'hbalharry4b', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1759, '5092-0727-0054-6347', 200067476.000000, '2017-06-27 00:00:00', 'akunzelr', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1760, '7589-0471-6735-5401', 444117776.000000, '2017-01-08 00:00:00', 'smantlm', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1761, '7327-6841-6103-5107', 410359488.000000, '2017-05-05 00:00:00', 'kcornejobs', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1762, '7998-0816-9249-5992', 413234574.000000, '2017-07-16 00:00:00', 'lleminggt', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1763, '9156-2306-0183-0385', 361452814.000000, '2017-03-13 00:00:00', 'rtigwellef', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1764, '2379-6060-8267-7139', 184298430.000000, '2017-07-27 00:00:00', 'wsilletto9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1765, '1772-4265-0104-8486', 242840958.000000, '2016-11-28 00:00:00', 'ilavingtonfm', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1766, '5835-9233-7689-1111', 265251568.000000, '2016-12-27 00:00:00', 'emauditt4s', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1767, '2109-5322-2196-3482', 330618256.000000, '2016-10-24 00:00:00', 'kdaubney1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1768, '8602-7362-1082-6366', 398971640.000000, '2017-03-26 00:00:00', 'sadrianello6w', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1769, '6576-6280-8889-9108', 402298687.000000, '2016-10-29 00:00:00', 'jduigenano3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1770, '7056-7918-1988-2836', 273272979.000000, '2017-07-13 00:00:00', 'gsainthille3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1771, '4709-7969-4885-5187', 396671071.000000, '2017-03-20 00:00:00', 'bmatousek6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1772, '8327-1459-3640-6015', 205732053.000000, '2017-01-15 00:00:00', 'amcquilkin24', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1773, '9261-3382-3016-6082', 222640529.000000, '2016-12-04 00:00:00', 'sbarizeretl1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1774, '2491-7738-6169-4478', 424481712.000000, '2017-01-17 00:00:00', 'sboddiscn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1775, '2543-2609-9528-0688', 236024920.000000, '2017-03-19 00:00:00', 'atrent97', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1776, '0077-8382-6894-1833', 292556594.000000, '2017-01-29 00:00:00', 'akunzelr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1777, '6186-9891-1392-0544', 437198128.000000, '2017-03-29 00:00:00', 'fkenrickj1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1778, '0207-6599-6207-7293', 383830872.000000, '2017-02-05 00:00:00', 'mguyer1i', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1779, '6847-4825-8553-5681', 435255364.000000, '2016-08-22 00:00:00', 'gcampsall8o', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1780, '7786-2488-0114-3528', 172440441.000000, '2017-06-21 00:00:00', 'kaspdenas', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1781, '1293-6124-3978-4095', 423376182.000000, '2016-10-30 00:00:00', 'mhinzernk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1782, '6555-6816-0646-2682', 182920098.000000, '2017-06-03 00:00:00', 'sbarizeretl1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1783, '9924-9845-7043-6223', 200689387.000000, '2016-12-02 00:00:00', 'fmagrane76', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1784, '7923-5977-0907-5796', 210704632.000000, '2016-12-11 00:00:00', 'tnaton7s', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1785, '0560-4661-1372-3656', 276149910.000000, '2017-03-14 00:00:00', 'blej', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1786, '5500-1286-3789-0175', 307796282.000000, '2017-05-12 00:00:00', 'mmacbean2t', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1787, '2612-5828-0172-4289', 303402702.000000, '2016-10-28 00:00:00', 'smellh1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1788, '4990-7591-5046-9079', 333293439.000000, '2017-03-15 00:00:00', 'cokenden75', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1789, '0684-6111-7709-1157', 387167554.000000, '2017-05-18 00:00:00', 'sspencer4d', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1790, '0303-9744-5598-1034', 369377751.000000, '2016-09-12 00:00:00', 'wmcduffie1j', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1791, '1143-1930-0572-7289', 226190398.000000, '2017-02-27 00:00:00', 'rkenealyj6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1792, '5213-1946-6403-3553', 375780619.000000, '2017-07-21 00:00:00', 'mdudbridgel5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1793, '5832-6937-3216-6329', 357401464.000000, '2016-10-26 00:00:00', 'kmurpheyfz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1794, '9218-1566-1068-6049', 212609007.000000, '2017-05-01 00:00:00', 'rimortgn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1795, '8711-8195-4783-1092', 373455677.000000, '2017-06-27 00:00:00', 'xmehewdb', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1796, '3232-3396-8859-4945', 199089967.000000, '2017-01-30 00:00:00', 'aelwelld1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1797, '4551-2589-7606-5608', 251508953.000000, '2017-05-12 00:00:00', 'sspencer4d', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1798, '0798-4948-4656-4453', 189590066.000000, '2016-09-18 00:00:00', 'amacnessmo', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1799, '8284-5047-3214-2991', 179976276.000000, '2017-05-22 00:00:00', 'rniccollsbu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1800, '3891-5908-7556-6405', 378770017.000000, '2017-01-26 00:00:00', 'tseareskc', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1801, '8950-2285-5040-4032', 179611464.000000, '2017-06-18 00:00:00', 'meastmondo5', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1802, '5166-2374-5347-4160', 335143057.000000, '2017-03-31 00:00:00', 'tollerf2', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1803, '0495-0274-6737-9516', 181079236.000000, '2017-01-08 00:00:00', 'kgosselin6e', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1804, '2792-9059-5930-6484', 187062747.000000, '2017-07-28 00:00:00', 'fjirickcl', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1805, '3897-2818-7764-7654', 440684707.000000, '2016-12-27 00:00:00', 'sspencer4d', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1806, '8728-0284-9812-6524', 353947721.000000, '2017-04-20 00:00:00', 'kthamep8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1807, '1810-2868-6592-1860', 432945233.000000, '2017-04-02 00:00:00', 'affoulkes83', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1808, '2226-7529-2167-0371', 176696739.000000, '2017-07-12 00:00:00', 'glamswood3y', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1809, '2864-4811-5832-3298', 383921951.000000, '2017-04-21 00:00:00', 'dgethingsaf', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1810, '0519-8443-6363-4791', 226033249.000000, '2016-11-10 00:00:00', 'wsilletto9', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1811, '5568-2696-5810-0516', 337325626.000000, '2017-06-12 00:00:00', 'sdancy7z', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1812, '6904-6818-2252-3788', 266934617.000000, '2017-04-08 00:00:00', 'do8c', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1813, '8438-2972-3579-8814', 418206771.000000, '2016-09-27 00:00:00', 'scoultl4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1814, '2705-5302-1866-9530', 236544035.000000, '2017-08-01 00:00:00', 'jjinkinsonok', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1815, '8351-7638-6418-0664', 191121690.000000, '2016-08-23 00:00:00', 'rcoomeriz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1816, '2952-6640-6879-5318', 409514644.000000, '2016-09-17 00:00:00', 'mdudnypi', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1817, '9955-6247-5740-6265', 187161021.000000, '2016-10-05 00:00:00', 'amallatrattm2', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1818, '1006-8363-7959-5345', 445765117.000000, '2017-04-07 00:00:00', 'lcicchinelliie', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1819, '4152-6436-1853-4550', 352668617.000000, '2016-09-14 00:00:00', 'psinclarr9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1820, '8192-2341-2023-3195', 255853661.000000, '2017-07-11 00:00:00', 'hlantaph35', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1821, '5146-4727-1765-5050', 323899861.000000, '2017-06-25 00:00:00', 'jburet5w', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1822, '1212-1898-2182-5009', 303380802.000000, '2017-05-10 00:00:00', 'ethirkettleij', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1823, '4469-1115-0179-3752', 318282264.000000, '2017-05-26 00:00:00', 'sadrianello6w', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1824, '3578-5937-5577-4200', 340936444.000000, '2017-01-22 00:00:00', 'rbriars95', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1825, '7603-4214-2216-1711', 373481116.000000, '2016-09-27 00:00:00', 'adooneynx', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1826, '3231-5665-9336-4930', 425117806.000000, '2017-03-04 00:00:00', 'glamswood3y', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1827, '5706-5268-7517-7328', 301547821.000000, '2016-08-21 00:00:00', 'jbaignardqa', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1828, '0500-8267-0385-3204', 268504163.000000, '2017-03-05 00:00:00', 'bcowdryn8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1829, '4041-1655-5923-0729', 353730406.000000, '2017-04-02 00:00:00', 'cashelfordhg', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1830, '8376-7939-9428-9693', 386430063.000000, '2017-07-15 00:00:00', 'sadrianello6w', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1831, '6669-0305-6209-5818', 197429262.000000, '2017-04-13 00:00:00', 'gtrenholmekm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1832, '9191-8786-5106-0667', 308863316.000000, '2016-11-11 00:00:00', 'bnajerad6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1833, '6949-2008-3748-8577', 319574931.000000, '2017-02-09 00:00:00', 'ldeloozer6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1834, '1895-4646-2215-5779', 194339160.000000, '2016-09-15 00:00:00', 'omccardlef5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1835, '3938-0252-3933-7528', 443475471.000000, '2016-12-22 00:00:00', 'nludwikiewiczir', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1836, '5255-9094-5380-8858', 300187536.000000, '2016-08-15 00:00:00', 'fdunckleyc9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1837, '7213-3694-2680-3233', 305608109.000000, '2017-04-11 00:00:00', 'heicke4g', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1838, '5063-8232-6239-0150', 433499661.000000, '2016-12-25 00:00:00', 'dbever14', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1839, '6914-6780-2252-4531', 204724697.000000, '2016-10-11 00:00:00', 'agladebeckjo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1840, '9237-4423-9181-6079', 303757561.000000, '2017-06-25 00:00:00', 'nspieghtnt', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1841, '6846-6981-4048-7296', 198401429.000000, '2016-08-16 00:00:00', 'osnookfn', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1842, '8970-0470-8363-0744', 434759877.000000, '2017-01-26 00:00:00', 'sschwandermannm3', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1843, '1259-1754-5933-9904', 227238459.000000, '2017-01-22 00:00:00', 'bforsdicke8v', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1844, '6736-4528-6431-4990', 262195131.000000, '2017-08-03 00:00:00', 'mgunthorpgy', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1845, '9603-6566-4780-2484', 427313592.000000, '2016-09-28 00:00:00', 'mbonnysonmh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1846, '4303-2080-5179-6157', 420303229.000000, '2017-01-04 00:00:00', 'lgiamoec', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1847, '0026-2816-9564-1013', 155140028.000000, '2017-07-17 00:00:00', 'kwilmut6x', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1848, '2437-1576-3404-9908', 422976108.000000, '2017-03-16 00:00:00', 'fduleydh', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1849, '7644-6681-1066-9493', 259719491.000000, '2017-01-02 00:00:00', 'tcoffeerp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1850, '9027-9750-8145-5379', 180905340.000000, '2017-04-22 00:00:00', 'dcollinette7q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1851, '8029-3357-1321-2734', 205779902.000000, '2016-08-04 00:00:00', 'nhugeninjx', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1852, '8447-8591-4374-9287', 224586361.000000, '2017-05-06 00:00:00', 'gduffrie2w', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1853, '9956-5857-4936-7706', 245265195.000000, '2016-10-02 00:00:00', 'mloy3j', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1854, '7029-1545-0892-4400', 182558330.000000, '2016-08-18 00:00:00', 'mpeltz5v', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1855, '7668-8112-2077-8420', 309004852.000000, '2017-02-12 00:00:00', 'tminettekf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1856, '4100-6594-6717-1670', 157535172.000000, '2017-06-11 00:00:00', 'aphillips', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1857, '0947-0978-6525-5862', 301363936.000000, '2017-08-04 00:00:00', 'santoninkp', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1858, '5461-3866-0547-6212', 297651260.000000, '2017-04-14 00:00:00', 'dhuzzeyq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1859, '3779-1660-9901-5439', 202431358.000000, '2017-04-07 00:00:00', 'tminettekf', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1860, '3202-8785-7610-1620', 193167761.000000, '2017-05-03 00:00:00', 'lwhetnallcb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1861, '7634-2860-1941-8213', 168629619.000000, '2017-04-07 00:00:00', 'adupreyg2', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1862, '8255-9599-2397-2235', 353909146.000000, '2017-05-06 00:00:00', 'ecarlesiib', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1863, '2691-9297-6444-7373', 306190853.000000, '2016-11-17 00:00:00', 'dhearlefh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1864, '7553-1142-5366-4335', 293952722.000000, '2016-10-21 00:00:00', 'joreagankr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1865, '4314-0768-0987-6657', 375567450.000000, '2017-01-10 00:00:00', 'etubblepb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1866, '4767-9095-0546-9814', 434916514.000000, '2016-10-30 00:00:00', 'oskipton96', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1867, '3985-9819-3116-5865', 226481231.000000, '2016-08-28 00:00:00', 'pjackmanqs', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1868, '7847-2436-8417-7320', 169862670.000000, '2016-10-25 00:00:00', 'lcicchinelliie', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1869, '5330-5848-7591-3934', 217684657.000000, '2017-01-02 00:00:00', 'vbenez16', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1870, '5572-5438-7645-6397', 411899349.000000, '2016-10-02 00:00:00', 'sbarizeretl1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1871, '9333-5118-1529-7984', 378511343.000000, '2016-11-14 00:00:00', 'rmeasham3r', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1872, '5759-8945-6212-8937', 177642500.000000, '2016-12-23 00:00:00', 'cwinder65', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1873, '8395-3917-3255-9601', 284209587.000000, '2016-10-15 00:00:00', 'kdaubney1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1874, '4131-2373-0165-9478', 438932530.000000, '2016-08-22 00:00:00', 'hmalcherli', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1875, '5033-5983-6056-9695', 328772137.000000, '2017-07-27 00:00:00', 'ctommasuzzijs', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1876, '0960-7222-9969-6257', 214481474.000000, '2017-07-11 00:00:00', 'mblackwood7y', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1877, '5486-6285-1590-0991', 264189414.000000, '2016-12-25 00:00:00', 'dcorrisong0', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1878, '4698-6390-5786-6178', 164171308.000000, '2017-05-18 00:00:00', 'rdominecao', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1879, '4342-2780-7568-5225', 343000790.000000, '2017-02-04 00:00:00', 'csetfordls', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1880, '7518-6779-3429-9920', 172733972.000000, '2017-03-20 00:00:00', 'fsirman9v', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1881, '3088-3945-1440-3580', 263014878.000000, '2016-11-15 00:00:00', 'cgeraschnm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1882, '4408-0595-7155-9372', 296420607.000000, '2017-02-15 00:00:00', 'blightbodyfj', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1883, '1033-2607-6812-4756', 287043274.000000, '2016-09-10 00:00:00', 'nspieghtnt', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1884, '3351-8284-2471-0010', 299575839.000000, '2017-01-25 00:00:00', 'cveillardc0', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1885, '0634-8834-4770-5595', 347740503.000000, '2017-08-04 00:00:00', 'lpetrion', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1886, '1208-7236-2812-7101', 221331024.000000, '2017-07-13 00:00:00', 'jblazyr5', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1887, '7122-1814-6549-4560', 185137737.000000, '2017-05-19 00:00:00', 'nmuge1v', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1888, '6768-3643-4256-4220', 420799006.000000, '2016-11-13 00:00:00', 'bbaystingny', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1889, '8591-9284-0584-6791', 369145638.000000, '2017-05-21 00:00:00', 'griden1h', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1890, '6777-1760-8793-1361', 258782805.000000, '2016-08-13 00:00:00', 'gdanzeygj', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1891, '3523-3487-9241-1570', 394028329.000000, '2016-08-04 00:00:00', 'mdudbridgel5', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1892, '2917-8025-4648-5433', 279003840.000000, '2016-11-08 00:00:00', 'bgaitskellr4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1893, '3322-4897-9107-1728', 411072875.000000, '2017-06-22 00:00:00', 'hdorsayiv', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1894, '1715-3197-2111-3732', 259205915.000000, '2017-02-05 00:00:00', 'jabelwhite5e', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1895, '6097-8025-5355-8835', 444931324.000000, '2017-06-03 00:00:00', 'ecoghlinpw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1896, '0608-5823-5376-5827', 350890226.000000, '2016-10-30 00:00:00', 'cjeacockpv', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1897, '1715-3747-1720-3476', 256897779.000000, '2016-12-31 00:00:00', 'rasletqd', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1898, '6190-5949-0687-4935', 421478298.000000, '2017-04-30 00:00:00', 'gcastellucci8i', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1899, '9021-7503-0770-8770', 333946380.000000, '2016-09-25 00:00:00', 'egarfathjq', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1900, '4290-0070-6740-7625', 316436292.000000, '2017-06-25 00:00:00', 'cvickersm7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1901, '0666-9829-4314-5827', 313097291.000000, '2016-10-23 00:00:00', 'gpyke32', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1902, '9627-0264-8010-2775', 343594213.000000, '2017-03-18 00:00:00', 'rbodemeaidqy', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1903, '9663-7399-2659-9823', 363472965.000000, '2017-06-25 00:00:00', 'po3n', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1904, '3855-6910-5022-2536', 164085495.000000, '2017-02-25 00:00:00', 'cedworthiee9', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1905, '4279-6890-8395-1948', 216813104.000000, '2017-05-08 00:00:00', 'dpochind4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1906, '6435-6102-6448-7735', 151553629.000000, '2017-03-19 00:00:00', 'nbroadyrc', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1907, '6311-4328-5738-9003', 219452156.000000, '2016-09-30 00:00:00', 'wnicklinsonhn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1908, '2848-2744-0190-5423', 420203487.000000, '2016-11-14 00:00:00', 'amaccafferky4j', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1909, '8873-8169-5351-4597', 195340245.000000, '2017-05-16 00:00:00', 'plohoaro7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1910, '4043-0854-4270-8728', 224381293.000000, '2017-01-23 00:00:00', 'hfairleighqc', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1911, '8474-4826-4105-1942', 268586984.000000, '2016-08-19 00:00:00', 'ajeannardbe', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1912, '1695-8142-0494-1325', 245208547.000000, '2016-08-27 00:00:00', 'ematticcinq', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1913, '8949-2140-6063-1411', 155238790.000000, '2017-05-16 00:00:00', 'hshewonho', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1914, '4054-9689-4325-5539', 161508034.000000, '2017-05-24 00:00:00', 'jcometti5k', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1915, '2555-8595-1981-5035', 246855088.000000, '2017-04-07 00:00:00', 'nmidfordhx', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1916, '8605-4497-9671-2082', 186708945.000000, '2017-01-13 00:00:00', 'cjzak9p', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1917, '5244-2130-6489-3790', 386879039.000000, '2016-09-12 00:00:00', 'psloraes', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1918, '4928-3149-3924-5463', 267163113.000000, '2017-03-12 00:00:00', 'jduigenano3', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1919, '5005-5947-1669-7433', 352219138.000000, '2017-06-22 00:00:00', 'agliddon73', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1920, '3647-6351-8394-2616', 413023073.000000, '2017-06-19 00:00:00', 'sschwandermannm3', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1921, '6891-4271-1973-2374', 267118060.000000, '2017-06-26 00:00:00', 'lpennyman9w', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1922, '9450-2942-2446-0134', 244512063.000000, '2016-09-11 00:00:00', 'trizzinik9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1923, '6492-8933-7311-0833', 414699768.000000, '2016-12-14 00:00:00', 'twenham82', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1924, '5466-0802-3043-9209', 234479888.000000, '2016-10-14 00:00:00', 'ko8z', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1925, '3000-3455-2371-2202', 312177461.000000, '2016-12-09 00:00:00', 'sspilisyf1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1926, '6129-3758-3370-1064', 228412929.000000, '2016-10-29 00:00:00', 'fjirickcl', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1927, '4951-5075-6890-1921', 434002953.000000, '2017-07-11 00:00:00', 'ldeloozer6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1928, '8808-7037-4636-5458', 437750457.000000, '2016-10-22 00:00:00', 'rcummine9c', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1929, '8342-8916-6091-0997', 332223110.000000, '2017-07-23 00:00:00', 'zschusterlft', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1930, '4102-3571-7578-9316', 419326287.000000, '2016-08-07 00:00:00', 'vnoriegaix', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1931, '6007-5744-6350-7012', 311239160.000000, '2016-10-07 00:00:00', 'gprendergast1u', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1932, '7550-2771-7686-5389', 234781405.000000, '2016-11-06 00:00:00', 'pbuttrumi0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1933, '8624-3519-7073-8889', 430330924.000000, '2017-06-11 00:00:00', 'dgemnettbl', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1934, '4951-7728-4865-7119', 365618044.000000, '2016-11-26 00:00:00', 'vwiltshawml', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1935, '4210-9603-8763-2613', 269278873.000000, '2017-02-15 00:00:00', 'joreagankr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1936, '0453-2833-3985-5714', 335970376.000000, '2016-11-30 00:00:00', 'vstreetgw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1937, '3215-9131-3810-9645', 440057017.000000, '2016-12-31 00:00:00', 'csangodq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1938, '9437-9631-0215-9569', 387780621.000000, '2017-01-09 00:00:00', 'jtoulson6d', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1939, '6111-8936-1243-3669', 380751374.000000, '2017-06-27 00:00:00', 'fbroome5i', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1940, '4913-8360-5886-2583', 429972930.000000, '2016-10-19 00:00:00', 'rnevison6o', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1941, '1630-2763-2918-1826', 268866417.000000, '2016-11-30 00:00:00', 'msharphurstqo', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1942, '0467-4180-3844-5016', 177601160.000000, '2017-05-24 00:00:00', 'zwhiteson6y', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1943, '6711-5787-2026-3049', 234935067.000000, '2017-07-18 00:00:00', 'mdashpermb', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1944, '8016-7570-0156-5732', 271972662.000000, '2016-12-08 00:00:00', 'hnajafianp3', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1945, '5312-6857-8329-4307', 335970328.000000, '2017-05-27 00:00:00', 'ckeppinmf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1946, '8492-1601-9003-0722', 355358761.000000, '2017-07-23 00:00:00', 'adonlonm5', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1947, '1850-5689-4698-5360', 189305821.000000, '2016-08-14 00:00:00', 'mcrallan2y', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1948, '5549-7201-3406-2052', 375165593.000000, '2017-05-21 00:00:00', 'ltomeoik', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1949, '2145-0817-1806-5619', 425138119.000000, '2016-08-23 00:00:00', 'bmatousek6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1950, '3386-4862-5982-2134', 155839571.000000, '2016-10-03 00:00:00', 'dvollethjz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1951, '8133-2840-6789-4226', 439923704.000000, '2016-11-14 00:00:00', 'rbartholomausdw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1952, '4207-6401-0561-6908', 259923035.000000, '2017-04-19 00:00:00', 'fgingell2s', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1953, '0918-4472-2848-7283', 422555774.000000, '2017-03-27 00:00:00', 'chargrovesiq', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1954, '1747-5102-2907-6287', 416058754.000000, '2017-05-08 00:00:00', 'rbartholomausdw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1955, '0409-6333-1242-5641', 216399630.000000, '2016-11-20 00:00:00', 'cusborn1m', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1956, '2301-0035-4173-7602', 340768547.000000, '2017-03-19 00:00:00', 'jcometti5k', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1957, '0972-2060-7570-4742', 215489344.000000, '2016-09-27 00:00:00', 'ranthon3g', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1958, '8400-7278-4743-0412', 302468340.000000, '2017-04-15 00:00:00', 'rclarycott7v', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1959, '1630-0325-3078-1771', 326518799.000000, '2016-09-24 00:00:00', 'eobroganegi', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1960, '9762-0319-9292-3843', 320988758.000000, '2017-04-15 00:00:00', 'sdancy7z', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1961, '3055-9395-0551-1743', 342920629.000000, '2016-11-27 00:00:00', 'khadwenkb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1962, '3690-3934-5226-0835', 150241137.000000, '2016-09-07 00:00:00', 'vohoolahan51', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1963, '6618-0714-7209-2612', 162738234.000000, '2016-08-09 00:00:00', 'kgaytherhu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1964, '8312-8004-6508-8521', 277130316.000000, '2016-08-16 00:00:00', 'zingleson4y', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1965, '6475-6514-2453-4835', 335743884.000000, '2017-07-01 00:00:00', 'aloisib4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1966, '8378-6768-8364-3911', 257970459.000000, '2016-12-31 00:00:00', 'jjinkinsonok', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1967, '4005-4766-2723-3197', 444432489.000000, '2016-12-16 00:00:00', 'vfilipczynskikl', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1968, '0687-8276-6997-1825', 328316224.000000, '2017-07-28 00:00:00', 'dputt84', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1969, '7990-8986-5243-0174', 333004222.000000, '2017-05-09 00:00:00', 'chobben9a', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1970, '6362-1048-2724-2482', 397777452.000000, '2016-12-30 00:00:00', 'erowlands94', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1971, '1103-8690-6162-9912', 318726334.000000, '2017-03-27 00:00:00', 'jbrookfield9g', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1972, '9312-3571-8136-5150', 379197543.000000, '2017-02-02 00:00:00', 'sizzetthc', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1973, '2541-3883-4415-5470', 385487415.000000, '2016-09-01 00:00:00', 'djessoppri', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1974, '1155-5855-4355-6453', 397754791.000000, '2017-02-19 00:00:00', 'cfoyston72', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1975, '0481-3816-5327-8449', 359443841.000000, '2016-11-08 00:00:00', 'hwyllcock1g', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1976, '7768-6079-3106-5111', 176266236.000000, '2017-06-13 00:00:00', 'rmichelov', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1977, '9976-0588-1601-7673', 255870214.000000, '2017-02-17 00:00:00', 'prennelsfu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1978, '9463-7248-4089-1277', 421636191.000000, '2016-09-30 00:00:00', 'kpapaf9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1979, '5537-9720-1139-0893', 386294278.000000, '2017-01-15 00:00:00', 'gmckuelk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1980, '4478-6872-9766-2388', 341915654.000000, '2017-04-10 00:00:00', 'gpyke32', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1981, '5737-9930-3751-6329', 168344342.000000, '2017-01-26 00:00:00', 'wsilletto9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1982, '4465-3058-5886-7856', 258544247.000000, '2016-09-15 00:00:00', 'rmagrane7f', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1983, '8745-2834-9122-8299', 284370412.000000, '2017-04-05 00:00:00', 'lmuzziq8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1984, '3562-0267-9135-6995', 423862388.000000, '2016-12-01 00:00:00', 'jbuttingq4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1985, '5830-2732-8025-4631', 391215834.000000, '2017-07-07 00:00:00', 'rronischfp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1986, '7306-9992-1336-8948', 264783055.000000, '2017-06-28 00:00:00', 'cbleymank8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1987, '1082-9900-0565-9255', 314612772.000000, '2016-10-07 00:00:00', 'lugolini77', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1988, '8466-9796-9588-7753', 165756563.000000, '2016-09-23 00:00:00', 'cnewbornd7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1989, '0356-9831-7390-6579', 392926512.000000, '2017-02-26 00:00:00', 'hmalcherli', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1990, '8468-1656-5592-5265', 430258198.000000, '2016-11-19 00:00:00', 'kgosselin6e', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1991, '9213-9472-8334-0889', 186390627.000000, '2016-12-29 00:00:00', 'ctucsellj3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1992, '8721-1513-2509-7767', 371956273.000000, '2017-03-03 00:00:00', 'rpetracchiot', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1993, '3546-4779-2181-9597', 422955565.000000, '2016-10-22 00:00:00', 'glemn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1994, '4568-2630-8285-9226', 449332421.000000, '2017-02-21 00:00:00', 'dcollinette7q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1995, '8682-7001-7740-8714', 196027777.000000, '2017-08-07 00:00:00', 'aloisib4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1996, '0403-3112-9590-3201', 298387409.000000, '2016-10-14 00:00:00', 'ikingswelljn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1997, '2018-6394-5751-8840', 252098245.000000, '2017-05-31 00:00:00', 'agliddon73', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1998, '7572-5956-2301-9837', 263033624.000000, '2016-11-03 00:00:00', 'levittsrk', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (1999, '2138-4325-5167-1782', 215614516.000000, '2016-10-17 00:00:00', 'dwittgl', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2000, '5844-8348-1804-8665', 164380735.000000, '2017-05-03 00:00:00', 'ashannahand0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2001, '4640-0341-9387-5781', 326577302.000000, '2017-04-07 00:00:00', 'ajustmi', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2002, '1630-2511-2937-7299', 192844907.000000, '2017-07-21 00:00:00', 'obreadmorehb', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2003, '6592-7866-3024-5314', 246481149.000000, '2016-09-12 00:00:00', 'amackaig8j', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2004, '1475-4858-1691-5789', 404928416.000000, '2017-02-08 00:00:00', 'qtilll6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2005, '3992-3343-8699-1754', 280934565.000000, '2017-07-24 00:00:00', 'lcicchinelliie', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2006, '9065-8351-4489-8687', 207844797.000000, '2016-12-10 00:00:00', 'cgoning6q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2007, '2928-4331-8647-0560', 256393732.000000, '2016-11-20 00:00:00', 'ngodfree8u', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2008, '7173-6253-2005-9312', 202995882.000000, '2017-06-04 00:00:00', 'tbullivantic', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2009, '6939-8463-2899-6921', 288281601.000000, '2017-01-16 00:00:00', 'bfyers55', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2010, '1215-0877-5497-4162', 416676129.000000, '2017-05-31 00:00:00', 'akunzelr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2011, '2632-3183-7851-1820', 237437446.000000, '2017-01-13 00:00:00', 'djambrozek9z', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2012, '9935-9879-2260-2925', 430249990.000000, '2016-08-02 00:00:00', 'nreidem4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2013, '9964-7808-5543-3283', 438362436.000000, '2016-12-15 00:00:00', 'ngodfree8u', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2014, '1029-9774-2970-1730', 231971457.000000, '2017-06-05 00:00:00', 'kgrenshields17', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2015, '4542-3132-7580-5698', 238897386.000000, '2016-11-08 00:00:00', 'eloades6b', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2016, '5476-9906-2825-9952', 401883223.000000, '2017-06-13 00:00:00', 'mchipps4t', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2017, '3730-3787-8629-3917', 158594784.000000, '2017-02-08 00:00:00', 'criediger2i', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2018, '1178-7900-5881-6552', 409651732.000000, '2017-03-12 00:00:00', 'dtumasianai', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2019, '5318-9901-9863-4382', 302900295.000000, '2017-06-07 00:00:00', 'mwilkisonnf', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2020, '0350-1117-8856-7980', 315955705.000000, '2017-02-07 00:00:00', 'lmccalisterk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2021, '6583-2282-3212-0467', 415221844.000000, '2017-02-17 00:00:00', 'gkeoghane2o', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2022, '1541-4277-0660-4459', 304657585.000000, '2016-12-05 00:00:00', 'bdafterlc', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2023, '9590-2625-2150-7258', 225503016.000000, '2017-07-12 00:00:00', 'ematticcinq', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2024, '0636-0754-0405-3314', 364415663.000000, '2017-07-19 00:00:00', 'ltomeoik', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2025, '2363-7005-2893-4182', 440656202.000000, '2016-11-04 00:00:00', 'govanesiang6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2026, '1683-9992-4718-7113', 212447917.000000, '2017-03-28 00:00:00', 'ckenninghamk4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2027, '5095-6341-6973-5274', 296814397.000000, '2017-06-07 00:00:00', 'cautiev', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2028, '9181-1189-4069-8436', 249240062.000000, '2017-04-28 00:00:00', 'lcicchinelliie', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2029, '1866-9428-1104-6886', 328882249.000000, '2016-11-16 00:00:00', 'lpetrion', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2030, '8278-7710-7311-4788', 218200567.000000, '2017-05-11 00:00:00', 'mmarushakb0', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2031, '4064-9491-1791-9866', 193334955.000000, '2017-05-08 00:00:00', 'jbrookfield9g', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2032, '0117-2729-2666-4999', 170260763.000000, '2017-02-03 00:00:00', 'sbarizeretl1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2033, '9455-7519-9184-1316', 300493865.000000, '2016-11-06 00:00:00', 'akunzelr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2034, '4489-2174-0669-7685', 193882298.000000, '2016-08-14 00:00:00', 'rbartholomausdw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2035, '6760-5797-6026-8236', 218287624.000000, '2016-12-14 00:00:00', 'taizlewoodbm', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2036, '0475-0347-5867-3706', 383210111.000000, '2016-11-01 00:00:00', 'bmatousek6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2037, '1164-3535-1779-9752', 275159296.000000, '2016-11-17 00:00:00', 'fmathiassen7l', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2038, '8918-2649-5470-5706', 376773288.000000, '2016-08-28 00:00:00', 'lrapi3u', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2039, '6499-7973-8172-6081', 331126499.000000, '2017-04-13 00:00:00', 'hshewonho', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2040, '8466-6269-4466-4874', 343679420.000000, '2017-02-14 00:00:00', 'acurcherb5', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2041, '9999-8370-6668-7190', 395799179.000000, '2017-04-15 00:00:00', 'mmussettinie0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2042, '7116-7842-3370-2242', 284362322.000000, '2017-06-03 00:00:00', 'amaccafferky4j', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2043, '7761-2171-6893-8685', 169086222.000000, '2017-07-01 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2044, '7486-5639-1437-3118', 435500877.000000, '2016-12-31 00:00:00', 'ecoghlinpw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2045, '3407-5270-2479-7393', 334193042.000000, '2017-06-10 00:00:00', 'jbastone9b', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2046, '2079-4572-9595-5154', 373563200.000000, '2016-10-31 00:00:00', 'sleisted', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2047, '6758-7942-1548-0121', 181362199.000000, '2016-10-26 00:00:00', 'uborithr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2048, '9591-3296-4863-4542', 387681347.000000, '2016-10-09 00:00:00', 'yreaperq9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2049, '1189-7024-1496-1936', 189230075.000000, '2017-01-26 00:00:00', 'sblomfieldeo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2050, '2632-8850-8767-6806', 373606113.000000, '2016-09-23 00:00:00', 'lgarbar3m', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2051, '9505-0277-8346-3969', 375165451.000000, '2017-02-28 00:00:00', 'gbroomheaddy', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2052, '2139-8397-7084-4093', 228385323.000000, '2016-08-01 00:00:00', 'nmuge1v', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2053, '8496-8115-5596-9722', 397103565.000000, '2017-05-03 00:00:00', 'mtrevettlp', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2054, '1078-8795-8240-6760', 174408190.000000, '2016-11-19 00:00:00', 'aphilipp4l', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2055, '6447-3132-2386-3059', 321821369.000000, '2017-03-13 00:00:00', 'qtilll6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2056, '4868-7136-8392-3176', 350587472.000000, '2017-02-19 00:00:00', 'eantico8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2057, '3803-6035-3793-4001', 239879540.000000, '2016-09-26 00:00:00', 'gcampsall8o', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2058, '4491-5667-1554-9630', 165468151.000000, '2017-06-03 00:00:00', 'haysikng', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2059, '0268-5280-7709-0786', 254805151.000000, '2017-06-02 00:00:00', 'sburnhamsp6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2060, '8949-3946-3107-0179', 246664106.000000, '2017-01-20 00:00:00', 'khabbershonb6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2061, '6121-8028-2625-4222', 222656923.000000, '2017-05-14 00:00:00', 'whatliffedm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2062, '8745-0201-1661-2523', 404336887.000000, '2017-01-15 00:00:00', 'ko8z', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2063, '4935-1821-8202-2968', 305922362.000000, '2016-11-05 00:00:00', 'ubavridgeoc', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2064, '6746-5524-6238-5271', 446116004.000000, '2017-04-30 00:00:00', 'cismirnioglou2p', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2065, '3526-8802-4949-4634', 289267429.000000, '2017-03-08 00:00:00', 'jmappeg', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2066, '7664-2611-7081-6632', 398371210.000000, '2016-08-03 00:00:00', 'edealeydp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2067, '6541-5717-5729-7113', 283339562.000000, '2017-07-28 00:00:00', 'smantlm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2068, '3372-1461-3357-0143', 179146728.000000, '2017-05-31 00:00:00', 'mdowsettqe', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2069, '9689-1520-0552-2257', 160641627.000000, '2016-09-10 00:00:00', 'ukernockecx', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2070, '2802-2131-5201-0271', 254510468.000000, '2016-09-30 00:00:00', 'mwolstenholme2r', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2071, '5206-5934-1915-3021', 348182612.000000, '2016-09-09 00:00:00', 'gcorre48', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2072, '6491-2184-3317-1931', 206977576.000000, '2017-02-18 00:00:00', 'jivashinnikovkz', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2073, '6635-4746-9618-9316', 202566372.000000, '2017-05-09 00:00:00', 'odebowb7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2074, '3368-0816-3360-9187', 422505306.000000, '2016-11-26 00:00:00', 'iodreaino6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2075, '5428-5398-1935-2463', 378496087.000000, '2016-10-01 00:00:00', 'wmckeadynl', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2076, '2650-5157-3672-6578', 281388126.000000, '2017-06-11 00:00:00', 'mnottinghamjf', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2077, '4192-8466-3559-0834', 169155733.000000, '2017-06-19 00:00:00', 'ggoldstona6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2078, '8203-9351-1310-1235', 178120596.000000, '2017-05-11 00:00:00', 'rthirstez', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2079, '9400-6128-0621-5409', 235152882.000000, '2017-05-13 00:00:00', 'kanelayhk', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2080, '4119-6950-3561-4992', 322851617.000000, '2016-10-25 00:00:00', 'trakestrawfl', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2081, '0346-9608-7387-6327', 259962696.000000, '2017-07-29 00:00:00', 'jtoulamainpo', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2082, '5622-1722-7571-8255', 159853087.000000, '2016-09-06 00:00:00', 'gmckuelk', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2083, '8959-5852-1379-0192', 308818339.000000, '2016-11-18 00:00:00', 'mpechan1s', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2084, '6557-7799-9961-8218', 308134824.000000, '2016-10-31 00:00:00', 'jverduinrr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2085, '0514-4787-8982-4300', 270640682.000000, '2016-08-03 00:00:00', 'rtigwellef', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2086, '0140-4923-2389-0727', 427774855.000000, '2017-02-09 00:00:00', 'emicohv', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2087, '3780-0383-1667-6535', 329313032.000000, '2017-03-10 00:00:00', 'alec', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2088, '1986-8035-6874-7565', 286639086.000000, '2017-02-05 00:00:00', 'lpennyman9w', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2089, '0820-4587-6824-7985', 320477357.000000, '2017-08-03 00:00:00', 'oskipton96', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2090, '4452-2795-2853-9523', 274844447.000000, '2017-02-05 00:00:00', 'cashelfordhg', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2091, '7401-6719-2903-4065', 238843580.000000, '2017-05-30 00:00:00', 'hbalharry4b', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2092, '9363-1099-8826-5566', 178352567.000000, '2017-04-11 00:00:00', 'jivashinnikovkz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2093, '1123-4560-6785-9543', 444783824.000000, '2017-07-02 00:00:00', 'ctolerel', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2094, '5551-1019-1170-6548', 386093017.000000, '2016-12-04 00:00:00', 'lpannerab', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2095, '6313-3080-5678-3858', 403909304.000000, '2017-06-12 00:00:00', 'awhitterpp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2096, '4710-8990-0069-3222', 192379783.000000, '2016-10-27 00:00:00', 'edealeydp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2097, '1363-2180-8920-1867', 405500086.000000, '2016-11-18 00:00:00', 'dhyettme', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2098, '0181-2541-5255-2584', 185344520.000000, '2016-12-20 00:00:00', 'atullochmu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2099, '7665-4361-2051-0234', 295622265.000000, '2017-06-03 00:00:00', 'scarette86', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2100, '3671-1051-5487-3782', 150609255.000000, '2017-01-19 00:00:00', 'sspencer4d', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2101, '6424-8071-9108-4502', 387537183.000000, '2017-05-11 00:00:00', 'lmcquorkelex', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2102, '7820-4469-0702-7629', 273270211.000000, '2016-10-16 00:00:00', 'hchat9t', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2103, '8208-5994-1776-8085', 237948746.000000, '2016-10-23 00:00:00', 'sgrieswood3o', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2104, '4981-4577-3614-8588', 409440137.000000, '2016-12-19 00:00:00', 'fmineror0', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2105, '7328-1152-9776-2856', 158226848.000000, '2017-07-29 00:00:00', 'mdeeream', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2106, '5477-1421-8772-8324', 169140606.000000, '2016-08-14 00:00:00', 'wwebbeqg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2107, '9319-6402-6367-9643', 319397335.000000, '2016-09-15 00:00:00', 'tpetchellhq', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2108, '0692-8676-7680-5833', 305678488.000000, '2016-09-26 00:00:00', 'marnaldyp9', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2109, '6853-1210-7083-5530', 372434000.000000, '2017-05-31 00:00:00', 'hspittlesr2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2110, '2107-2630-0013-7168', 343397642.000000, '2017-05-22 00:00:00', 'dgomerlu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2111, '2530-4884-4726-8684', 262969418.000000, '2016-08-06 00:00:00', 'griden1h', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2112, '9153-0285-9063-5908', 222540019.000000, '2017-05-01 00:00:00', 'jnicklen30', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2113, '0074-8367-8071-1220', 389794375.000000, '2017-06-19 00:00:00', 'gprendergast1u', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2114, '0081-7911-8197-5581', 183184890.000000, '2016-10-21 00:00:00', 'mblytha1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2115, '2893-6865-7692-8052', 309910200.000000, '2017-01-20 00:00:00', 'rhaineyi7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2116, '8730-6745-7677-0461', 234595364.000000, '2017-01-06 00:00:00', 'gkretschmerat', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2117, '1405-4442-6573-5897', 193967216.000000, '2016-12-06 00:00:00', 'fvalentinettird', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2118, '1648-0781-3078-1877', 276207195.000000, '2017-03-25 00:00:00', 'ltemplemancy', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2119, '8309-1029-1985-4355', 335013627.000000, '2016-11-29 00:00:00', 'bwitseyo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2120, '2221-0754-3973-1051', 381478037.000000, '2016-09-27 00:00:00', 'mmarushakb0', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2121, '4785-7858-5902-0580', 252793387.000000, '2017-05-07 00:00:00', 'mkewzick22', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2122, '9452-0825-2091-3906', 279806491.000000, '2017-04-01 00:00:00', 'channis4r', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2123, '7790-6384-6955-0766', 159461845.000000, '2017-01-21 00:00:00', 'dtowers3a', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2124, '2329-7925-9726-5030', 402315959.000000, '2017-06-19 00:00:00', 'ctolerel', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2125, '6642-6674-6250-1202', 248687162.000000, '2016-08-25 00:00:00', 'santoninkp', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2126, '3925-5240-3610-2141', 379501779.000000, '2016-08-26 00:00:00', 'dskullyg4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2127, '6415-4192-3179-9426', 440341652.000000, '2016-08-12 00:00:00', 'rfrede2c', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2128, '5952-2699-9699-3113', 277883974.000000, '2017-02-01 00:00:00', 'mmclaffertygm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2129, '0841-2249-8886-5338', 369135726.000000, '2017-02-17 00:00:00', 'rmagrane7f', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2130, '3304-1266-4460-0809', 409186383.000000, '2017-07-31 00:00:00', 'aduffellq2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2131, '7591-2485-8429-7497', 333531060.000000, '2016-10-24 00:00:00', 'cmartyntsevaw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2132, '7872-2526-6619-2504', 237862523.000000, '2017-06-27 00:00:00', 'tnajerapk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2133, '8208-5565-5813-1453', 184489548.000000, '2016-12-15 00:00:00', 'sbriscamnj', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2134, '6761-5503-3356-1971', 356286005.000000, '2017-05-05 00:00:00', 'aanlaynu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2135, '9446-5312-0194-9512', 197921497.000000, '2017-03-10 00:00:00', 'dantic79', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2136, '4593-9532-3041-7011', 293363884.000000, '2017-04-15 00:00:00', 'pbrumfitt4k', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2137, '1373-6024-9204-8582', 414596905.000000, '2016-10-17 00:00:00', 'mblytha1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2138, '9564-8786-5763-0311', 288053982.000000, '2016-08-21 00:00:00', 'apattissonpq', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2139, '6889-0041-6232-5724', 273794933.000000, '2016-11-14 00:00:00', 'itwentymank0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2140, '4377-0106-3176-8044', 303549342.000000, '2017-06-10 00:00:00', 'ecarlesiib', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2141, '0093-0717-7855-8621', 389632237.000000, '2016-08-12 00:00:00', 'ccriellya8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2142, '5498-8953-4099-5133', 294407908.000000, '2017-03-18 00:00:00', 'lbevisa3', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2143, '4159-0519-3146-3812', 430594840.000000, '2017-01-26 00:00:00', 'vstreetgw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2144, '2177-9204-5855-2340', 326770979.000000, '2016-08-14 00:00:00', 'gmorbey44', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2145, '4408-7236-9916-1891', 185051184.000000, '2017-06-08 00:00:00', 'jtoulamainpo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2146, '0822-7068-9243-8891', 198055890.000000, '2017-01-20 00:00:00', 'jgriswaiteh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2147, '1780-2902-1963-8625', 439071075.000000, '2017-03-24 00:00:00', 'lbloxland21', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2148, '9704-9929-7178-8103', 180903049.000000, '2016-08-20 00:00:00', 'gmorbey44', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2149, '1778-8428-8990-5968', 420375098.000000, '2017-06-22 00:00:00', 'jbridgett9n', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2150, '0177-7899-6206-8106', 396113536.000000, '2016-10-19 00:00:00', 'ygonsalvo74', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2151, '9899-9870-2438-3478', 162890211.000000, '2017-02-25 00:00:00', 'amchirrier8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2152, '4170-9568-1904-9980', 420638393.000000, '2017-04-03 00:00:00', 'sswate9s', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2153, '9827-9591-6662-0112', 284990316.000000, '2016-11-18 00:00:00', 'fonolandoi', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2154, '9409-0563-8504-7287', 252443647.000000, '2017-02-10 00:00:00', 'avellenderms', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2155, '9811-1722-5045-0670', 352339501.000000, '2016-10-02 00:00:00', 'lbloxland21', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2156, '9350-0086-1238-0376', 414015454.000000, '2017-03-01 00:00:00', 'fmathiassen7l', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2157, '3605-7164-4531-3983', 326166823.000000, '2016-11-27 00:00:00', 'mfolibr', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2158, '2387-4116-3699-0044', 327967031.000000, '2017-04-09 00:00:00', 'slumsdall8w', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2159, '4327-3699-3991-5248', 311980517.000000, '2016-12-18 00:00:00', 'pkirkupf7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2160, '8057-8052-0967-7029', 449731880.000000, '2017-07-08 00:00:00', 'mpeltz5v', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2161, '2125-2796-8386-1777', 379158880.000000, '2017-01-31 00:00:00', 'cfishpond2a', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2162, '7111-5132-7995-5089', 211730904.000000, '2016-12-23 00:00:00', 'lshortland1f', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2163, '4305-2519-0729-1255', 183408779.000000, '2017-07-24 00:00:00', 'slaxenhj', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2164, '2819-7576-2967-7617', 274482996.000000, '2017-04-29 00:00:00', 'no39', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2165, '7600-5534-7912-7650', 269792343.000000, '2016-11-21 00:00:00', 'dbever14', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2166, '0031-0825-4207-7451', 444935464.000000, '2017-06-05 00:00:00', 'bshealga', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2167, '9494-1375-9599-2451', 393165937.000000, '2017-03-04 00:00:00', 'sburnhamsp6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2168, '7785-2013-9754-1083', 405977664.000000, '2016-10-10 00:00:00', 'vkonertgz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2169, '6690-3842-6103-9519', 291001370.000000, '2016-11-04 00:00:00', 'estarmorejm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2170, '2639-9433-6813-5967', 326307077.000000, '2016-12-06 00:00:00', 'cvickersm7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2171, '6646-0588-6217-9747', 286950509.000000, '2017-01-17 00:00:00', 'rchippingf3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2172, '6549-6805-4081-8635', 351017547.000000, '2017-01-18 00:00:00', 'ppirnieeu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2173, '8004-0166-8784-4683', 259420659.000000, '2017-03-04 00:00:00', 'atarge3k', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2174, '8881-4291-1393-9206', 234164759.000000, '2017-03-28 00:00:00', 'zingleson4y', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2175, '1628-4469-4254-4255', 387502001.000000, '2016-10-26 00:00:00', 'khadwenkb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2176, '8552-0405-6197-9901', 276432336.000000, '2017-06-14 00:00:00', 'sfather2q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2177, '9883-5961-6517-4010', 301385650.000000, '2016-12-05 00:00:00', 'smellh1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2178, '3084-3732-4361-0086', 233518228.000000, '2016-08-25 00:00:00', 'jscotchbrookgk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2179, '0746-0674-7223-5619', 298883587.000000, '2017-04-01 00:00:00', 'mwolstenholme2r', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2180, '2280-1779-0471-5318', 189881881.000000, '2017-07-06 00:00:00', 'chaylor4m', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2181, '5545-1357-9636-3169', 248339362.000000, '2016-09-06 00:00:00', 'sbroadbridge7i', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2182, '3583-8213-4143-9711', 345253357.000000, '2017-06-24 00:00:00', 'ssawlci', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2183, '5081-7006-2463-0217', 162339977.000000, '2016-09-27 00:00:00', 'egarfathjq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2184, '0625-5789-0933-9728', 324490377.000000, '2016-09-09 00:00:00', 'cedworthiee9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2185, '0140-2787-6477-4524', 409575164.000000, '2016-08-16 00:00:00', 'ecollyearo1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2186, '4821-3301-7746-1349', 427443022.000000, '2016-08-16 00:00:00', 'cwinder65', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2187, '9606-1585-2060-8079', 158512044.000000, '2017-02-03 00:00:00', 'disoldi9i', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2188, '5467-3923-1765-7151', 434730307.000000, '2017-04-03 00:00:00', 'sglantonq3', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2189, '0097-7698-8413-7348', 258391343.000000, '2016-09-13 00:00:00', 'cwaleworke3t', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2190, '1508-2064-2026-7610', 245397191.000000, '2017-07-20 00:00:00', 'lhitteria', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2191, '0276-7149-2926-4746', 250787296.000000, '2016-08-24 00:00:00', 'wrowenaew', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2192, '5345-1932-3298-5325', 383861108.000000, '2017-06-10 00:00:00', 'tbullivantic', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2193, '6387-3084-2819-5638', 192256411.000000, '2017-07-26 00:00:00', 'mtollmachee', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2194, '2374-2534-7359-2444', 331637316.000000, '2016-12-30 00:00:00', 'tbullivantic', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2195, '8263-6894-0909-0911', 264642078.000000, '2017-02-24 00:00:00', 'nreidem4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2196, '3376-3270-3265-3518', 166528219.000000, '2017-01-20 00:00:00', 'ctucsellj3', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2197, '6941-1137-1293-6653', 163005720.000000, '2016-11-10 00:00:00', 'nhugeninjx', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2198, '0075-6185-1037-6321', 285620488.000000, '2017-01-15 00:00:00', 'mdowsettqe', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2199, '1100-7332-6663-8295', 243476555.000000, '2017-06-03 00:00:00', 'mgarlicl9', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2200, '8580-4430-7584-2750', 398327006.000000, '2017-05-26 00:00:00', 'rlowfr', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2201, '9392-5951-1261-6862', 332130320.000000, '2017-02-23 00:00:00', 'mgarlicl9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2202, '6208-3887-9872-0419', 449452098.000000, '2017-05-06 00:00:00', 'tglyne90', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2203, '5998-1286-0435-2887', 434857015.000000, '2017-04-03 00:00:00', 'ekobierzyckib9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2204, '8722-1029-6046-2103', 287033054.000000, '2017-08-01 00:00:00', 'rkenealyj6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2205, '6876-3354-5583-1458', 253630022.000000, '2017-05-13 00:00:00', 'ewhiteoak3l', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2206, '3915-5119-8398-0697', 231118901.000000, '2017-04-09 00:00:00', 'mhinzernk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2207, '6879-9953-6602-9061', 235973557.000000, '2016-08-11 00:00:00', 'edicheob', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2208, '2998-6007-0135-7091', 212439213.000000, '2016-08-12 00:00:00', 'hdanagd', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2209, '7016-8978-9924-1613', 253452897.000000, '2016-11-07 00:00:00', 'acastillagr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2210, '3535-2449-5558-7697', 285425259.000000, '2017-02-05 00:00:00', 'cgeraschnm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2211, '8000-2272-1003-6653', 369772984.000000, '2016-08-19 00:00:00', 'mjoe53', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2212, '0941-9567-9911-0938', 444998313.000000, '2017-07-05 00:00:00', 'tdreelan58', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2213, '9865-7398-8744-4357', 285310597.000000, '2017-02-23 00:00:00', 'rbabb31', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2214, '4348-8697-9298-2108', 254365955.000000, '2016-12-14 00:00:00', 'tcoffeerp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2215, '6953-0000-0012-2654', 394428197.000000, '2017-04-04 00:00:00', 'khabbershonb6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2216, '9372-1718-0849-8844', 335635508.000000, '2017-02-13 00:00:00', 'sadrianello6w', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2217, '5374-2352-9131-4756', 339093508.000000, '2017-02-21 00:00:00', 'ufowler46', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2218, '4490-3980-7238-8700', 204145860.000000, '2017-02-10 00:00:00', 'tbaptistare', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2219, '4759-7971-8874-1491', 250310186.000000, '2017-01-18 00:00:00', 'cismirnioglou2p', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2220, '5414-2120-4147-4860', 261921112.000000, '2016-12-07 00:00:00', 'ddjokovicnw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2221, '6771-5490-2874-7421', 257975363.000000, '2017-03-29 00:00:00', 'ajeannardbe', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2222, '6130-3140-1930-7167', 280080553.000000, '2017-02-26 00:00:00', 'tglyne90', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2223, '7671-7317-0267-7964', 284361427.000000, '2016-12-11 00:00:00', 'wbottleson3e', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2224, '1679-2509-6968-7377', 408268563.000000, '2016-11-10 00:00:00', 'mkochslz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2225, '7366-7385-3876-8415', 414765395.000000, '2017-01-31 00:00:00', 'dwittgl', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2226, '6735-0858-7744-7994', 401626920.000000, '2017-02-27 00:00:00', 'vohoolahan51', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2227, '9047-7506-0162-0489', 190802304.000000, '2017-06-20 00:00:00', 'jjaggarlb', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2228, '7881-2895-3447-1545', 260011575.000000, '2017-04-26 00:00:00', 'ctwinborneld', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2229, '1244-3751-3519-7016', 186671626.000000, '2017-07-19 00:00:00', 'sdaymondc1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2230, '7800-5498-7867-5837', 159014731.000000, '2017-03-14 00:00:00', 'bhoneyghan5z', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2231, '1218-5597-4263-9081', 423092529.000000, '2017-07-14 00:00:00', 'nbroadyrc', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2232, '5123-5612-7316-1987', 363983946.000000, '2016-12-10 00:00:00', 'ehatchard9j', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2233, '0605-9991-1349-8896', 329935741.000000, '2016-09-28 00:00:00', 'hlameyom', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2234, '6024-2414-7844-5037', 167147985.000000, '2017-05-26 00:00:00', 'cabramzon85', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2235, '3564-5733-3113-4933', 245201946.000000, '2016-12-14 00:00:00', 'csuerone', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2236, '3163-6133-3780-5137', 213368419.000000, '2016-11-17 00:00:00', 'bfyers55', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2237, '7629-4189-1211-5218', 159878164.000000, '2017-03-06 00:00:00', 'btockellfw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2238, '2370-4863-9564-5049', 424593584.000000, '2016-11-19 00:00:00', 'elebbernrh', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2239, '6703-6438-5781-3618', 443385316.000000, '2017-04-10 00:00:00', 'fwedmoreqb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2240, '9512-2858-0859-3287', 216955883.000000, '2017-03-15 00:00:00', 'rkenealyj6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2241, '7168-3838-8848-0614', 367909390.000000, '2016-09-30 00:00:00', 'estarmorejm', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2242, '2425-7395-8704-0178', 187278016.000000, '2017-05-20 00:00:00', 'ggalliver4a', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2243, '3118-9370-9608-0660', 433326260.000000, '2017-07-31 00:00:00', 'rnevison6o', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2244, '0714-1131-7491-7867', 405014098.000000, '2016-08-01 00:00:00', 'sbeldam8d', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2245, '3787-9057-2673-4768', 179447551.000000, '2016-10-28 00:00:00', 'dgethingsaf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2246, '6926-2835-3378-2241', 222416601.000000, '2017-02-25 00:00:00', 'ljammet9e', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2247, '6927-8165-6542-7138', 384648816.000000, '2016-09-01 00:00:00', 'mwiddecombehw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2248, '6288-7006-5475-6661', 373196363.000000, '2017-06-11 00:00:00', 'psloraes', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2249, '1832-9622-2825-4224', 333117348.000000, '2016-09-09 00:00:00', 'mpochethh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2250, '1232-4421-2594-5281', 168741065.000000, '2016-09-26 00:00:00', 'msarton2d', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2251, '1486-3459-0435-3155', 159828333.000000, '2016-08-06 00:00:00', 'gkeoghane2o', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2252, '8910-8488-8040-7169', 156204687.000000, '2017-04-24 00:00:00', 'cyettsbi', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2253, '6243-5359-5834-3643', 234192669.000000, '2016-09-30 00:00:00', 'lpettingalldf', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2254, '3349-8388-9044-8651', 347558113.000000, '2017-06-27 00:00:00', 'khaken7m', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2255, '3030-5344-0883-5346', 335723336.000000, '2017-06-05 00:00:00', 'pkleingrub4f', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2256, '3652-8402-2084-3744', 373808359.000000, '2017-01-11 00:00:00', 'vkonertgz', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2257, '1283-8610-4212-9730', 244988597.000000, '2017-05-06 00:00:00', 'mtorriem1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2258, '9634-2056-2795-7015', 152561154.000000, '2017-05-27 00:00:00', 'lyockney8g', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2259, '5092-0727-0054-6347', 259960379.000000, '2017-04-07 00:00:00', 'lkinneally1x', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2260, '7589-0471-6735-5401', 308966998.000000, '2016-10-19 00:00:00', 'motridgeky', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2261, '7327-6841-6103-5107', 307360093.000000, '2016-10-11 00:00:00', 'tgovern20', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2262, '7998-0816-9249-5992', 288374101.000000, '2016-09-13 00:00:00', 'lugolini77', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2263, '9156-2306-0183-0385', 187731639.000000, '2017-03-21 00:00:00', 'mfolibr', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2264, '2379-6060-8267-7139', 412941720.000000, '2017-02-05 00:00:00', 'psinclarr9', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2265, '1772-4265-0104-8486', 389735853.000000, '2017-04-06 00:00:00', 'mbonnysonmh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2266, '5835-9233-7689-1111', 204998862.000000, '2017-07-26 00:00:00', 'acripin2v', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2267, '2109-5322-2196-3482', 288965276.000000, '2016-10-08 00:00:00', 'tnilesiy', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2268, '8602-7362-1082-6366', 180567727.000000, '2017-06-20 00:00:00', 'sheckle9m', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2269, '6576-6280-8889-9108', 312332733.000000, '2017-08-05 00:00:00', 'pyve7a', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2270, '7056-7918-1988-2836', 227808150.000000, '2016-11-13 00:00:00', 'arake9y', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2271, '4709-7969-4885-5187', 214120185.000000, '2016-11-23 00:00:00', 'mjuschkemq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2272, '8327-1459-3640-6015', 234666516.000000, '2016-10-29 00:00:00', 'caisthorpe25', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2273, '9261-3382-3016-6082', 193854836.000000, '2017-02-21 00:00:00', 'rsandifordji', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2274, '2491-7738-6169-4478', 304015834.000000, '2017-01-22 00:00:00', 'dstoddly', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2275, '2543-2609-9528-0688', 229125571.000000, '2016-08-16 00:00:00', 'pprobyncg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2276, '0077-8382-6894-1833', 244905051.000000, '2016-12-21 00:00:00', 'fduleydh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2277, '6186-9891-1392-0544', 403182397.000000, '2017-01-29 00:00:00', 'nwalsh6l', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2278, '0207-6599-6207-7293', 349995424.000000, '2017-07-22 00:00:00', 'mfinckendv', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2279, '6847-4825-8553-5681', 349519351.000000, '2016-09-25 00:00:00', 'vkenealyqx', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2280, '7786-2488-0114-3528', 290404284.000000, '2016-12-23 00:00:00', 'estarmorejm', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2281, '1293-6124-3978-4095', 209571627.000000, '2016-11-28 00:00:00', 'sspilisyf1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2282, '6555-6816-0646-2682', 377515730.000000, '2016-09-24 00:00:00', 'dhoutbyfa', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2283, '9924-9845-7043-6223', 304552310.000000, '2017-07-29 00:00:00', 'adoogood10', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2284, '7923-5977-0907-5796', 321164713.000000, '2017-07-04 00:00:00', 'mnottinghamjf', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2285, '0560-4661-1372-3656', 419908846.000000, '2017-01-28 00:00:00', 'mantunez6a', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2286, '5500-1286-3789-0175', 192152331.000000, '2017-05-17 00:00:00', 'smenureil', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2287, '2612-5828-0172-4289', 241708505.000000, '2017-06-03 00:00:00', 'cdampierkg', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2288, '4990-7591-5046-9079', 155689525.000000, '2016-10-14 00:00:00', 'eloades6b', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2289, '0684-6111-7709-1157', 243357733.000000, '2017-03-02 00:00:00', 'abengallke', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2290, '0303-9744-5598-1034', 313372469.000000, '2017-07-16 00:00:00', 'kgaytherhu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2291, '1143-1930-0572-7289', 333175630.000000, '2016-08-28 00:00:00', 'rchoulertoni8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2292, '5213-1946-6403-3553', 193317973.000000, '2016-11-12 00:00:00', 'sfather2q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2293, '5832-6937-3216-6329', 261765721.000000, '2017-02-11 00:00:00', 'mdashpermb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2294, '9218-1566-1068-6049', 174289078.000000, '2016-08-27 00:00:00', 'cdampierkg', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2295, '8711-8195-4783-1092', 277776186.000000, '2016-08-19 00:00:00', 'rwithamf6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2296, '3232-3396-8859-4945', 214217285.000000, '2017-04-13 00:00:00', 'cmactrustie41', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2297, '4551-2589-7606-5608', 173228035.000000, '2017-06-23 00:00:00', 'trakestrawfl', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2298, '0798-4948-4656-4453', 282779032.000000, '2016-08-28 00:00:00', 'ltomeoik', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2299, '8284-5047-3214-2991', 401947106.000000, '2016-11-05 00:00:00', 'wjeaycock4o', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2300, '3891-5908-7556-6405', 199493994.000000, '2016-08-29 00:00:00', 'ukernockecx', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2301, '8950-2285-5040-4032', 290786073.000000, '2017-06-02 00:00:00', 'jphysick33', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2302, '5166-2374-5347-4160', 364784670.000000, '2017-06-24 00:00:00', 'msharphurstqo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2303, '0495-0274-6737-9516', 200026219.000000, '2016-08-17 00:00:00', 'kgaytherhu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2304, '2792-9059-5930-6484', 277106665.000000, '2017-03-11 00:00:00', 'tstrainkw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2305, '3897-2818-7764-7654', 405778214.000000, '2017-02-26 00:00:00', 'mbeddowsg9', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2306, '8728-0284-9812-6524', 408634342.000000, '2016-08-23 00:00:00', 'bbiasi99', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2307, '1810-2868-6592-1860', 424813942.000000, '2017-04-11 00:00:00', 'tenzleymz', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2308, '2226-7529-2167-0371', 232030586.000000, '2016-08-08 00:00:00', 'dbaymanow', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2309, '2864-4811-5832-3298', 356422287.000000, '2016-11-16 00:00:00', 'ponele7b', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2310, '0519-8443-6363-4791', 260950834.000000, '2016-11-19 00:00:00', 'jgriswaiteh', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2311, '5568-2696-5810-0516', 442595574.000000, '2017-06-17 00:00:00', 'pkleingrub4f', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2312, '6904-6818-2252-3788', 349192476.000000, '2016-10-25 00:00:00', 'bdumingoscf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2313, '8438-2972-3579-8814', 353992224.000000, '2016-12-17 00:00:00', 'gtorransqz', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2314, '2705-5302-1866-9530', 270471009.000000, '2017-04-24 00:00:00', 'pmcallev', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2315, '8351-7638-6418-0664', 300536856.000000, '2017-07-02 00:00:00', 'sguye5y', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2316, '2952-6640-6879-5318', 216325161.000000, '2017-06-25 00:00:00', 'dmontegs', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2317, '9955-6247-5740-6265', 227502080.000000, '2016-12-24 00:00:00', 'cismirnioglou2p', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2318, '1006-8363-7959-5345', 397514919.000000, '2016-08-06 00:00:00', 'ayielding6m', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2319, '4152-6436-1853-4550', 201852339.000000, '2016-08-16 00:00:00', 'sdevasqn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2320, '8192-2341-2023-3195', 209689525.000000, '2017-07-24 00:00:00', 'ejacmar5t', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2321, '5146-4727-1765-5050', 413249652.000000, '2016-12-25 00:00:00', 'sdrewsqq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2322, '1212-1898-2182-5009', 287647040.000000, '2016-11-10 00:00:00', 'lshortland1f', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2323, '4469-1115-0179-3752', 308280522.000000, '2016-12-23 00:00:00', 'atullochmu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2324, '3578-5937-5577-4200', 249786213.000000, '2017-07-15 00:00:00', 'bdafterlc', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2325, '7603-4214-2216-1711', 332609272.000000, '2017-06-12 00:00:00', 'ko8z', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2326, '3231-5665-9336-4930', 190026165.000000, '2017-07-22 00:00:00', 'oivakindg', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2327, '5706-5268-7517-7328', 308373927.000000, '2017-04-28 00:00:00', 'cmcgerraghtydx', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2328, '0500-8267-0385-3204', 186082405.000000, '2017-06-30 00:00:00', 'cthoroldfe', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2329, '4041-1655-5923-0729', 270527522.000000, '2016-11-10 00:00:00', 'cdantonilg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2330, '8376-7939-9428-9693', 216559239.000000, '2017-01-14 00:00:00', 'bdaskiewiczb1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2331, '6669-0305-6209-5818', 274361583.000000, '2016-11-23 00:00:00', 'visaksond', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2332, '9191-8786-5106-0667', 157331474.000000, '2016-09-10 00:00:00', 'gboullin7u', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2333, '6949-2008-3748-8577', 217366882.000000, '2016-11-19 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2334, '1895-4646-2215-5779', 249437506.000000, '2017-01-08 00:00:00', 'psloraes', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2335, '3938-0252-3933-7528', 182781364.000000, '2016-10-05 00:00:00', 'vgreen9k', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2336, '5255-9094-5380-8858', 179952037.000000, '2017-07-19 00:00:00', 'dbever14', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2337, '7213-3694-2680-3233', 329053092.000000, '2017-05-14 00:00:00', 'nbroadyrc', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2338, '5063-8232-6239-0150', 231937238.000000, '2016-12-24 00:00:00', 'jbastone9b', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2339, '6914-6780-2252-4531', 158331326.000000, '2017-04-05 00:00:00', 'amacnessmo', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2340, '9237-4423-9181-6079', 316140479.000000, '2017-04-27 00:00:00', 'tboweringn7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2341, '6846-6981-4048-7296', 379545849.000000, '2017-04-04 00:00:00', 'hculprf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2342, '8970-0470-8363-0744', 193771893.000000, '2017-01-28 00:00:00', 'lgarbar3m', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2343, '1259-1754-5933-9904', 366211383.000000, '2016-12-20 00:00:00', 'fkenrickj1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2344, '6736-4528-6431-4990', 395641219.000000, '2016-11-10 00:00:00', 'lveschif8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2345, '9603-6566-4780-2484', 159317603.000000, '2016-08-24 00:00:00', 'kwyvill52', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2346, '4303-2080-5179-6157', 439321192.000000, '2017-08-02 00:00:00', 'bdaskiewiczb1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2347, '0026-2816-9564-1013', 257314263.000000, '2017-07-09 00:00:00', 'affoulkes83', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2348, '2437-1576-3404-9908', 186148645.000000, '2017-01-10 00:00:00', 'xquereerb', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2349, '7644-6681-1066-9493', 250909467.000000, '2016-12-10 00:00:00', 'lamericikd', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2350, '9027-9750-8145-5379', 253845267.000000, '2016-11-21 00:00:00', 'rbriston18', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2351, '8029-3357-1321-2734', 153202134.000000, '2017-01-25 00:00:00', 'nbarkero4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2352, '8447-8591-4374-9287', 302736691.000000, '2017-06-26 00:00:00', 'pfordycebh', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2353, '9956-5857-4936-7706', 221441160.000000, '2017-05-07 00:00:00', 'acossum40', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2354, '7029-1545-0892-4400', 374697436.000000, '2017-03-02 00:00:00', 'komoylanebb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2355, '7668-8112-2077-8420', 239192118.000000, '2016-10-09 00:00:00', 'grarityal', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2356, '4100-6594-6717-1670', 241946466.000000, '2016-09-11 00:00:00', 'fmutimer59', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2357, '0947-0978-6525-5862', 220206072.000000, '2017-03-09 00:00:00', 'ppirnieeu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2358, '5461-3866-0547-6212', 184677124.000000, '2016-11-29 00:00:00', 'hbreami1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2359, '3779-1660-9901-5439', 295735404.000000, '2016-12-11 00:00:00', 'hwyllcock1g', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2360, '3202-8785-7610-1620', 192678700.000000, '2017-01-28 00:00:00', 'mmayoralct', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2361, '7634-2860-1941-8213', 326354541.000000, '2016-12-18 00:00:00', 'do8c', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2362, '8255-9599-2397-2235', 342959714.000000, '2016-11-09 00:00:00', 'hbalharry4b', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2363, '2691-9297-6444-7373', 202223708.000000, '2017-04-02 00:00:00', 'xquereerb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2364, '7553-1142-5366-4335', 183733538.000000, '2016-08-05 00:00:00', 'emessam50', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2365, '4314-0768-0987-6657', 282188374.000000, '2016-10-01 00:00:00', 'dcollinette7q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2366, '4767-9095-0546-9814', 296540560.000000, '2017-06-15 00:00:00', 'jyokleylx', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2367, '3985-9819-3116-5865', 332268443.000000, '2017-05-01 00:00:00', 'ecoghlinpw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2368, '7847-2436-8417-7320', 274379680.000000, '2016-09-27 00:00:00', 'rfoakes7r', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2369, '5330-5848-7591-3934', 333157779.000000, '2017-04-21 00:00:00', 'ecaress5q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2370, '5572-5438-7645-6397', 246423113.000000, '2016-08-12 00:00:00', 'cdampierkg', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2371, '9333-5118-1529-7984', 307248370.000000, '2016-12-20 00:00:00', 'cantat9d', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2372, '5759-8945-6212-8937', 218271684.000000, '2017-05-06 00:00:00', 'csuerone', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2373, '8395-3917-3255-9601', 436505325.000000, '2016-11-08 00:00:00', 'hkilbourneoo', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2374, '4131-2373-0165-9478', 276836972.000000, '2016-09-28 00:00:00', 'cmcindrewbt', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2375, '5033-5983-6056-9695', 289644506.000000, '2017-06-24 00:00:00', 'dlongridgehp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2376, '0960-7222-9969-6257', 305436324.000000, '2017-06-02 00:00:00', 'ckenninghamk4', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2377, '5486-6285-1590-0991', 415428870.000000, '2017-01-03 00:00:00', 'tbowmakerko', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2378, '4698-6390-5786-6178', 298063445.000000, '2017-04-15 00:00:00', 'mbonnysonmh', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2379, '4342-2780-7568-5225', 247718998.000000, '2017-05-04 00:00:00', 'cglyneq1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2380, '7518-6779-3429-9920', 237412948.000000, '2016-10-13 00:00:00', 'dghelardig1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2381, '3088-3945-1440-3580', 251057071.000000, '2016-09-01 00:00:00', 'ioharaqh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2382, '4408-0595-7155-9372', 380088217.000000, '2017-06-15 00:00:00', 'ckillingbeckoe', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2383, '1033-2607-6812-4756', 308436223.000000, '2016-11-21 00:00:00', 'uborithr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2384, '3351-8284-2471-0010', 176108555.000000, '2016-11-19 00:00:00', 'noliveirafs', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2385, '0634-8834-4770-5595', 340354534.000000, '2017-05-05 00:00:00', 'tsnodinge8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2386, '1208-7236-2812-7101', 212737520.000000, '2016-12-21 00:00:00', 'lbloxland21', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2387, '7122-1814-6549-4560', 186661616.000000, '2017-04-19 00:00:00', 'uborithr', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2388, '6768-3643-4256-4220', 356975981.000000, '2016-12-24 00:00:00', 'acossum40', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2389, '8591-9284-0584-6791', 235691019.000000, '2017-02-01 00:00:00', 'sdaymondc1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2390, '6777-1760-8793-1361', 374006348.000000, '2017-05-16 00:00:00', 'tchristauffour8a', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2391, '3523-3487-9241-1570', 197199052.000000, '2017-02-03 00:00:00', 'ggarfitt92', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2392, '2917-8025-4648-5433', 424738903.000000, '2017-01-28 00:00:00', 'cdonovanbj', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2393, '3322-4897-9107-1728', 280462990.000000, '2016-09-08 00:00:00', 'lhurley5a', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2394, '1715-3197-2111-3732', 189314381.000000, '2016-11-05 00:00:00', 'emicohv', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2395, '6097-8025-5355-8835', 255440915.000000, '2016-09-07 00:00:00', 'mdibnahd9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2396, '0608-5823-5376-5827', 339653422.000000, '2016-09-17 00:00:00', 'aloganip', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2397, '1715-3747-1720-3476', 304027671.000000, '2017-01-07 00:00:00', 'acluseaj', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2398, '6190-5949-0687-4935', 294904017.000000, '2017-02-17 00:00:00', 'rcoomeriz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2399, '9021-7503-0770-8770', 213546115.000000, '2017-02-19 00:00:00', 'jgriswaiteh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2400, '4290-0070-6740-7625', 232428815.000000, '2016-11-09 00:00:00', 'pnation8l', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2401, '0666-9829-4314-5827', 169298904.000000, '2017-05-13 00:00:00', 'wdanilovitchjl', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2402, '9627-0264-8010-2775', 160856170.000000, '2016-09-12 00:00:00', 'blosbie3w', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2403, '9663-7399-2659-9823', 445471715.000000, '2017-08-03 00:00:00', 'mmarushakb0', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2404, '3855-6910-5022-2536', 302616509.000000, '2016-12-11 00:00:00', 'tscollandki', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2405, '4279-6890-8395-1948', 165290665.000000, '2017-01-01 00:00:00', 'mbutson1c', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2406, '6435-6102-6448-7735', 216617032.000000, '2016-11-14 00:00:00', 'lduffilnz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2407, '6311-4328-5738-9003', 172738946.000000, '2016-08-20 00:00:00', 'jashpolein', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2408, '2848-2744-0190-5423', 241565244.000000, '2017-06-12 00:00:00', 'sthebeaudbp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2409, '8873-8169-5351-4597', 253300754.000000, '2016-08-16 00:00:00', 'mmayoralct', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2410, '4043-0854-4270-8728', 192849638.000000, '2017-05-17 00:00:00', 'bbattermy', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2411, '8474-4826-4105-1942', 173778418.000000, '2017-05-14 00:00:00', 'arichiek6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2412, '1695-8142-0494-1325', 272546650.000000, '2017-03-26 00:00:00', 'jscotchbrookgk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2413, '8949-2140-6063-1411', 436069040.000000, '2017-05-30 00:00:00', 'mfayter67', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2414, '4054-9689-4325-5539', 161188356.000000, '2016-11-19 00:00:00', 'edealeydp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2415, '2555-8595-1981-5035', 284055070.000000, '2017-01-10 00:00:00', 'mdeeream', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2416, '8605-4497-9671-2082', 431611201.000000, '2017-05-29 00:00:00', 'lclue2j', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2417, '5244-2130-6489-3790', 174243402.000000, '2017-05-06 00:00:00', 'mbartosch7h', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2418, '4928-3149-3924-5463', 259358596.000000, '2017-03-12 00:00:00', 'ftwentyman2b', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2419, '5005-5947-1669-7433', 224905036.000000, '2016-12-22 00:00:00', 'jbrookfield9g', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2420, '3647-6351-8394-2616', 166440782.000000, '2016-08-28 00:00:00', 'cautiev', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2421, '6891-4271-1973-2374', 220857366.000000, '2017-05-01 00:00:00', 'ihallumjv', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2422, '9450-2942-2446-0134', 303961642.000000, '2017-04-27 00:00:00', 'mswindenf', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2423, '6492-8933-7311-0833', 423414603.000000, '2016-09-28 00:00:00', 'jgriswaiteh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2424, '5466-0802-3043-9209', 162304638.000000, '2017-04-20 00:00:00', 'cnevinsna', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2425, '3000-3455-2371-2202', 242472018.000000, '2016-12-06 00:00:00', 'amackaig8j', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2426, '6129-3758-3370-1064', 253856603.000000, '2017-03-15 00:00:00', 'gcattoncr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2427, '4951-5075-6890-1921', 200338405.000000, '2017-03-11 00:00:00', 'mpotterypm', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2428, '8808-7037-4636-5458', 430801457.000000, '2016-10-05 00:00:00', 'vkonertgz', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2429, '8342-8916-6091-0997', 384733893.000000, '2016-09-27 00:00:00', 'jtrett6i', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2430, '4102-3571-7578-9316', 321203544.000000, '2017-02-28 00:00:00', 'gmckuelk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2431, '6007-5744-6350-7012', 282809976.000000, '2017-01-02 00:00:00', 'nbarkero4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2432, '7550-2771-7686-5389', 435780099.000000, '2017-03-16 00:00:00', 'epicktonpr', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2433, '8624-3519-7073-8889', 255630837.000000, '2016-10-08 00:00:00', 'lleminggt', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2434, '4951-7728-4865-7119', 320369112.000000, '2017-04-02 00:00:00', 'nklemz4u', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2435, '4210-9603-8763-2613', 183646205.000000, '2017-03-04 00:00:00', 'mpilmoordu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2436, '0453-2833-3985-5714', 264004044.000000, '2017-01-06 00:00:00', 'do8c', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2437, '3215-9131-3810-9645', 272553740.000000, '2016-09-07 00:00:00', 'bdafterlc', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2438, '9437-9631-0215-9569', 151831603.000000, '2017-07-29 00:00:00', 'mcornell7j', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2439, '6111-8936-1243-3669', 400340141.000000, '2017-07-17 00:00:00', 'jbuttingq4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2440, '4913-8360-5886-2583', 345716795.000000, '2016-10-18 00:00:00', 'ccriellya8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2441, '1630-2763-2918-1826', 250946786.000000, '2017-05-09 00:00:00', 'ggalliver4a', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2442, '0467-4180-3844-5016', 439295690.000000, '2017-03-28 00:00:00', 'tnaton7s', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2443, '6711-5787-2026-3049', 449380735.000000, '2016-10-29 00:00:00', 'smantlm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2444, '8016-7570-0156-5732', 274959657.000000, '2017-04-06 00:00:00', 'komoylanebb', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2445, '5312-6857-8329-4307', 150910985.000000, '2017-01-14 00:00:00', 'sdancy7z', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2446, '8492-1601-9003-0722', 389971104.000000, '2017-01-04 00:00:00', 'mfarndaleff', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2447, '1850-5689-4698-5360', 231582257.000000, '2016-12-11 00:00:00', 'aphillips', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2448, '5549-7201-3406-2052', 399916196.000000, '2016-10-11 00:00:00', 'gtorransqz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2449, '2145-0817-1806-5619', 336352706.000000, '2017-06-02 00:00:00', 'nspieghtnt', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2450, '3386-4862-5982-2134', 202318340.000000, '2017-06-14 00:00:00', 'nsousaja', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2451, '8133-2840-6789-4226', 259172744.000000, '2016-12-18 00:00:00', 'blosbie3w', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2452, '4207-6401-0561-6908', 302909829.000000, '2017-05-19 00:00:00', 'wmcduffie1j', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2453, '0918-4472-2848-7283', 371113341.000000, '2017-06-11 00:00:00', 'mdashpermb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2454, '1747-5102-2907-6287', 222989683.000000, '2017-07-30 00:00:00', 'lmuzziq8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2455, '0409-6333-1242-5641', 351871245.000000, '2017-06-05 00:00:00', 'rchoulertoni8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2456, '2301-0035-4173-7602', 378824849.000000, '2016-11-14 00:00:00', 'yreaperq9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2457, '0972-2060-7570-4742', 429956502.000000, '2017-01-07 00:00:00', 'slaxenhj', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2458, '8400-7278-4743-0412', 200307532.000000, '2017-07-27 00:00:00', 'eobroganegi', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2459, '1630-0325-3078-1771', 395698105.000000, '2017-01-22 00:00:00', 'cmcgerraghtydx', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2460, '9762-0319-9292-3843', 169810061.000000, '2017-06-12 00:00:00', 'kwickey7w', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2461, '3055-9395-0551-1743', 381003361.000000, '2016-11-03 00:00:00', 'mnottinghamjf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2462, '3690-3934-5226-0835', 409596104.000000, '2017-05-22 00:00:00', 'wwebbeqg', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2463, '6618-0714-7209-2612', 394375897.000000, '2016-09-08 00:00:00', 'lzanettohs', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2464, '8312-8004-6508-8521', 247343438.000000, '2017-04-20 00:00:00', 'kdawdrybk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2465, '6475-6514-2453-4835', 236567699.000000, '2017-05-24 00:00:00', 'blightbodyfj', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2466, '8378-6768-8364-3911', 181949832.000000, '2017-06-25 00:00:00', 'dvollethjz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2467, '4005-4766-2723-3197', 163138178.000000, '2017-07-20 00:00:00', 'rwhyliefg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2468, '0687-8276-6997-1825', 349199865.000000, '2016-10-23 00:00:00', 'aloisib4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2469, '7990-8986-5243-0174', 329676724.000000, '2017-05-06 00:00:00', 'featockim', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2470, '6362-1048-2724-2482', 283571581.000000, '2017-06-21 00:00:00', 'gdanfortho0', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2471, '1103-8690-6162-9912', 173460903.000000, '2017-02-02 00:00:00', 'denburyee', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2472, '9312-3571-8136-5150', 264996223.000000, '2017-03-30 00:00:00', 'rsandifordji', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2473, '2541-3883-4415-5470', 260889990.000000, '2017-02-27 00:00:00', 'tsidnell2l', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2474, '1155-5855-4355-6453', 405799436.000000, '2016-09-06 00:00:00', 'mlavies8n', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2475, '0481-3816-5327-8449', 155597267.000000, '2017-03-28 00:00:00', 'mmattiaccirn', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2476, '7768-6079-3106-5111', 265732871.000000, '2017-05-14 00:00:00', 'mdashpermb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2477, '9976-0588-1601-7673', 405444764.000000, '2016-12-14 00:00:00', 'nreidem4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2478, '9463-7248-4089-1277', 285551704.000000, '2017-06-17 00:00:00', 'cvickersm7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2479, '5537-9720-1139-0893', 157693990.000000, '2017-04-07 00:00:00', 'nmcgeneayb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2480, '4478-6872-9766-2388', 241496889.000000, '2016-10-22 00:00:00', 'tminettekf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2481, '5737-9930-3751-6329', 377924176.000000, '2017-02-15 00:00:00', 'bmatousek6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2482, '4465-3058-5886-7856', 178595380.000000, '2016-08-20 00:00:00', 'blightbodyfj', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2483, '8745-2834-9122-8299', 190103552.000000, '2017-06-17 00:00:00', 'cgeraschnm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2484, '3562-0267-9135-6995', 424328135.000000, '2017-03-31 00:00:00', 'sdancy7z', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2485, '5830-2732-8025-4631', 444947275.000000, '2016-09-27 00:00:00', 'rpetracchiot', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2486, '7306-9992-1336-8948', 202456872.000000, '2016-08-14 00:00:00', 'khaken7m', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2487, '1082-9900-0565-9255', 196730864.000000, '2016-12-30 00:00:00', 'scoultl4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2488, '8466-9796-9588-7753', 259512252.000000, '2016-11-18 00:00:00', 'rbriston18', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2489, '0356-9831-7390-6579', 224913386.000000, '2017-02-23 00:00:00', 'tmcvityhe', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2490, '8468-1656-5592-5265', 256198162.000000, '2017-04-06 00:00:00', 'mblytha1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2491, '9213-9472-8334-0889', 396676385.000000, '2016-09-11 00:00:00', 'wcattermolel3', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2492, '8721-1513-2509-7767', 385890630.000000, '2017-06-14 00:00:00', 'nludwikiewiczir', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2493, '3546-4779-2181-9597', 158557226.000000, '2016-12-25 00:00:00', 'nmuge1v', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2494, '4568-2630-8285-9226', 221669009.000000, '2017-01-25 00:00:00', 'bnibloe1o', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2495, '8682-7001-7740-8714', 421936184.000000, '2017-05-25 00:00:00', 'ahartas68', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2496, '0403-3112-9590-3201', 154642985.000000, '2017-01-16 00:00:00', 'psinclarr9', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2497, '2018-6394-5751-8840', 243967693.000000, '2017-05-31 00:00:00', 'lgarbar3m', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2498, '7572-5956-2301-9837', 336562958.000000, '2017-01-29 00:00:00', 'gdanzeygj', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2499, '2138-4325-5167-1782', 229726798.000000, '2016-10-16 00:00:00', 'hcordobesfi', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2500, '5844-8348-1804-8665', 184308457.000000, '2017-06-11 00:00:00', 'dtoopecv', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2501, '4640-0341-9387-5781', 198452339.000000, '2017-03-04 00:00:00', 'dwittgl', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2502, '1630-2511-2937-7299', 321905965.000000, '2016-11-03 00:00:00', 'jburet5w', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2503, '6592-7866-3024-5314', 227033827.000000, '2017-01-29 00:00:00', 'adonlonm5', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2504, '1475-4858-1691-5789', 244900520.000000, '2017-08-03 00:00:00', 'nsnaith3', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2505, '3992-3343-8699-1754', 219122541.000000, '2017-07-18 00:00:00', 'gmernerep', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2506, '9065-8351-4489-8687', 351383351.000000, '2017-03-31 00:00:00', 'emcilwreathj8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2507, '2928-4331-8647-0560', 444529143.000000, '2017-05-31 00:00:00', 'yalabone15', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2508, '7173-6253-2005-9312', 300558843.000000, '2016-11-01 00:00:00', 'emarien57', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2509, '6939-8463-2899-6921', 326312614.000000, '2017-07-03 00:00:00', 'lgarbar3m', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2510, '1215-0877-5497-4162', 317164150.000000, '2016-12-28 00:00:00', 'mbartosch7h', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2511, '2632-3183-7851-1820', 379846577.000000, '2017-06-17 00:00:00', 'rfrede2c', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2512, '9935-9879-2260-2925', 440873523.000000, '2016-11-18 00:00:00', 'vkonertgz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2513, '9964-7808-5543-3283', 328741536.000000, '2016-12-17 00:00:00', 'gvaskovmw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2514, '1029-9774-2970-1730', 295914899.000000, '2017-07-17 00:00:00', 'iodreaino6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2515, '4542-3132-7580-5698', 275599593.000000, '2016-10-01 00:00:00', 'lpannerab', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2516, '5476-9906-2825-9952', 235072961.000000, '2016-12-05 00:00:00', 'mkewzick22', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2517, '3730-3787-8629-3917', 155561543.000000, '2017-07-29 00:00:00', 'tdupoy7x', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2518, '1178-7900-5881-6552', 341060229.000000, '2017-03-08 00:00:00', 'akeerl9o', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2519, '5318-9901-9863-4382', 278356330.000000, '2016-12-13 00:00:00', 'mvelarealoy', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2520, '0350-1117-8856-7980', 443133823.000000, '2017-06-08 00:00:00', 'rbriars95', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2521, '6583-2282-3212-0467', 344420148.000000, '2016-12-30 00:00:00', 'imcgarrieln', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2522, '1541-4277-0660-4459', 384540482.000000, '2017-06-18 00:00:00', 'ggarfitt92', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2523, '9590-2625-2150-7258', 169006817.000000, '2017-02-14 00:00:00', 'cstormsp1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2524, '0636-0754-0405-3314', 423675740.000000, '2017-01-21 00:00:00', 'sthebeaudbp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2525, '2363-7005-2893-4182', 269307626.000000, '2017-06-19 00:00:00', 'gtrenholmekm', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2526, '1683-9992-4718-7113', 435900096.000000, '2017-07-20 00:00:00', 'cgrichukhanovo2', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2527, '5095-6341-6973-5274', 317299637.000000, '2017-06-11 00:00:00', 'pjackmanqs', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2528, '9181-1189-4069-8436', 449917638.000000, '2016-12-02 00:00:00', 'mcalderpy', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2529, '1866-9428-1104-6886', 372193330.000000, '2017-04-27 00:00:00', 'mtenneyn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2530, '8278-7710-7311-4788', 182286395.000000, '2017-03-19 00:00:00', 'blej', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2531, '4064-9491-1791-9866', 204493849.000000, '2017-07-02 00:00:00', 'sgrieswood3o', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2532, '0117-2729-2666-4999', 240083262.000000, '2016-08-27 00:00:00', 'okennionle', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2533, '9455-7519-9184-1316', 261518811.000000, '2016-10-19 00:00:00', 'cvickersm7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2534, '4489-2174-0669-7685', 167219933.000000, '2017-07-07 00:00:00', 'bmccloyl0', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2535, '6760-5797-6026-8236', 158283080.000000, '2016-10-07 00:00:00', 'cwinder65', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2536, '0475-0347-5867-3706', 210985395.000000, '2017-07-02 00:00:00', 'mdudnypi', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2537, '1164-3535-1779-9752', 267936930.000000, '2017-02-27 00:00:00', 'rthackerayhy', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2538, '8918-2649-5470-5706', 254474449.000000, '2016-11-24 00:00:00', 'jmappeg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2539, '6499-7973-8172-6081', 411725966.000000, '2016-11-30 00:00:00', 'gbaribal7k', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2540, '8466-6269-4466-4874', 430424752.000000, '2017-02-05 00:00:00', 'ggirlingn0', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2541, '9999-8370-6668-7190', 211662918.000000, '2016-10-16 00:00:00', 'cmartyntsevaw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2542, '7116-7842-3370-2242', 404668277.000000, '2016-08-11 00:00:00', 'sburnhamsp6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2543, '7761-2171-6893-8685', 396679320.000000, '2016-08-17 00:00:00', 'tjasperqf', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2544, '7486-5639-1437-3118', 358184544.000000, '2016-08-22 00:00:00', 'ddenington89', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2545, '3407-5270-2479-7393', 392006268.000000, '2017-02-20 00:00:00', 'haysikng', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2546, '2079-4572-9595-5154', 206315783.000000, '2016-09-18 00:00:00', 'hshewonho', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2547, '6758-7942-1548-0121', 269213059.000000, '2017-01-01 00:00:00', 'osnookfn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2548, '9591-3296-4863-4542', 437705566.000000, '2016-10-28 00:00:00', 'tjasperqf', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2549, '1189-7024-1496-1936', 177652501.000000, '2017-06-07 00:00:00', 'tsnodinge8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2550, '2632-8850-8767-6806', 255583793.000000, '2016-10-02 00:00:00', 'callbrook0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2551, '9505-0277-8346-3969', 263988770.000000, '2017-07-18 00:00:00', 'adrancepa', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2552, '2139-8397-7084-4093', 277397167.000000, '2017-06-26 00:00:00', 'trakestrawfl', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2553, '8496-8115-5596-9722', 193168666.000000, '2017-04-24 00:00:00', 'amorelandkn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2554, '1078-8795-8240-6760', 270656311.000000, '2016-08-07 00:00:00', 'cmeechou', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2555, '6447-3132-2386-3059', 445289869.000000, '2016-12-09 00:00:00', 'gbagnalag', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2556, '4868-7136-8392-3176', 246942123.000000, '2017-04-26 00:00:00', 'jdomnickra', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2557, '3803-6035-3793-4001', 158993751.000000, '2017-05-27 00:00:00', 'rhaineyi7', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2558, '4491-5667-1554-9630', 250068347.000000, '2016-10-26 00:00:00', 'otheobaldj7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2559, '0268-5280-7709-0786', 363905165.000000, '2017-06-07 00:00:00', 'cmactrustie41', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2560, '8949-3946-3107-0179', 331911933.000000, '2017-08-01 00:00:00', 'rmichelov', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2561, '6121-8028-2625-4222', 184382923.000000, '2016-12-04 00:00:00', 'dolahy12', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2562, '8745-0201-1661-2523', 279587167.000000, '2017-05-09 00:00:00', 'lcasbolt8', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2563, '4935-1821-8202-2968', 394273816.000000, '2017-05-12 00:00:00', 'agladebeckjo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2564, '6746-5524-6238-5271', 325496586.000000, '2017-01-03 00:00:00', 'slorrimerjj', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2565, '3526-8802-4949-4634', 224023476.000000, '2017-05-10 00:00:00', 'msarton2d', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2566, '7664-2611-7081-6632', 421985911.000000, '2017-06-08 00:00:00', 'mcassinlv', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2567, '6541-5717-5729-7113', 225177335.000000, '2016-08-18 00:00:00', 'rmancejw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2568, '3372-1461-3357-0143', 203506428.000000, '2017-02-13 00:00:00', 'mtorriem1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2569, '9689-1520-0552-2257', 320839419.000000, '2017-06-20 00:00:00', 'mloy3j', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2570, '2802-2131-5201-0271', 209491179.000000, '2016-12-19 00:00:00', 'gsavage3p', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2571, '5206-5934-1915-3021', 287763874.000000, '2017-07-31 00:00:00', 'mswindenf', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2572, '6491-2184-3317-1931', 242624327.000000, '2017-05-21 00:00:00', 'ijeanonpg', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2573, '6635-4746-9618-9316', 313838364.000000, '2017-03-30 00:00:00', 'tdalmanjd', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2574, '3368-0816-3360-9187', 230572054.000000, '2016-10-11 00:00:00', 'ahealeasnr', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2575, '5428-5398-1935-2463', 430276216.000000, '2017-06-03 00:00:00', 'pfordycebh', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2576, '2650-5157-3672-6578', 301205847.000000, '2017-05-19 00:00:00', 'tboweringn7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2577, '4192-8466-3559-0834', 331615433.000000, '2016-12-22 00:00:00', 'rdamantcw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2578, '8203-9351-1310-1235', 165759522.000000, '2017-05-12 00:00:00', 'lwhetnallcb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2579, '9400-6128-0621-5409', 305022360.000000, '2017-06-16 00:00:00', 'cabramzon85', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2580, '4119-6950-3561-4992', 253157125.000000, '2016-11-11 00:00:00', 'chobben9a', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2581, '0346-9608-7387-6327', 238477213.000000, '2016-12-09 00:00:00', 'cgoning6q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2582, '5622-1722-7571-8255', 441383344.000000, '2016-08-27 00:00:00', 'bmatthewscm', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2583, '8959-5852-1379-0192', 245900563.000000, '2016-11-09 00:00:00', 'dcahnhm', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2584, '6557-7799-9961-8218', 191955121.000000, '2017-03-17 00:00:00', 'emauditt4s', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2585, '0514-4787-8982-4300', 369670059.000000, '2017-07-15 00:00:00', 'cmckimgg', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2586, '0140-4923-2389-0727', 340812820.000000, '2016-12-04 00:00:00', 'aarnett2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2587, '3780-0383-1667-6535', 160348669.000000, '2017-02-25 00:00:00', 'mtenneyn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2588, '1986-8035-6874-7565', 440320875.000000, '2017-05-18 00:00:00', 'tmcvityhe', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2589, '0820-4587-6824-7985', 152405620.000000, '2016-12-07 00:00:00', 'cyettsbi', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2590, '4452-2795-2853-9523', 184952326.000000, '2016-09-19 00:00:00', 'lmoodycliffeoq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2591, '7401-6719-2903-4065', 315757224.000000, '2017-04-13 00:00:00', 'sstrother2n', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2592, '9363-1099-8826-5566', 259057775.000000, '2016-09-21 00:00:00', 'mtrevettlp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2593, '1123-4560-6785-9543', 280788086.000000, '2016-12-03 00:00:00', 'ckeenlyside6j', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2594, '5551-1019-1170-6548', 167839547.000000, '2017-05-16 00:00:00', 'ilavingtonfm', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2595, '6313-3080-5678-3858', 387928354.000000, '2016-11-01 00:00:00', 'aloisib4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2596, '4710-8990-0069-3222', 415104143.000000, '2017-03-04 00:00:00', 'arake9y', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2597, '1363-2180-8920-1867', 373290081.000000, '2016-11-12 00:00:00', 'mpotterypm', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2598, '0181-2541-5255-2584', 408218832.000000, '2016-10-02 00:00:00', 'ecarlesiib', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2599, '7665-4361-2051-0234', 263767767.000000, '2017-06-29 00:00:00', 'wwebbeqg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2600, '3671-1051-5487-3782', 242525561.000000, '2017-05-09 00:00:00', 'aphilipp4l', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2601, '6424-8071-9108-4502', 310815423.000000, '2017-01-15 00:00:00', 'iodreaino6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2602, '7820-4469-0702-7629', 261440152.000000, '2017-02-24 00:00:00', 'dghelardig1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2603, '8208-5994-1776-8085', 188315554.000000, '2017-03-08 00:00:00', 'mblytha1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2604, '4981-4577-3614-8588', 256279301.000000, '2017-03-01 00:00:00', 'dgemnettbl', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2605, '7328-1152-9776-2856', 359441609.000000, '2016-08-01 00:00:00', 'adrancepa', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2606, '5477-1421-8772-8324', 361258917.000000, '2017-06-01 00:00:00', 'lbrisbane9x', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2607, '9319-6402-6367-9643', 442674818.000000, '2017-01-26 00:00:00', 'pbuttrumi0', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2608, '0692-8676-7680-5833', 191976639.000000, '2017-04-16 00:00:00', 'rroddanlt', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2609, '6853-1210-7083-5530', 356272513.000000, '2016-09-02 00:00:00', 'abackson6n', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2610, '2107-2630-0013-7168', 421090255.000000, '2017-06-03 00:00:00', 'vshalec4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2611, '2530-4884-4726-8684', 347570809.000000, '2017-04-02 00:00:00', 'agladebeckjo', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2612, '9153-0285-9063-5908', 307574411.000000, '2017-08-05 00:00:00', 'jburet5w', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2613, '0074-8367-8071-1220', 247857481.000000, '2017-07-20 00:00:00', 'tnaton7s', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2614, '0081-7911-8197-5581', 185393071.000000, '2016-10-16 00:00:00', 'pyve7a', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2615, '2893-6865-7692-8052', 154595772.000000, '2017-05-27 00:00:00', 'fduleydh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2616, '8730-6745-7677-0461', 412469347.000000, '2017-04-23 00:00:00', 'kyuryatin3f', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2617, '1405-4442-6573-5897', 230921134.000000, '2017-06-12 00:00:00', 'bjolleydi', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2618, '1648-0781-3078-1877', 308867499.000000, '2017-03-30 00:00:00', 'efraczaknb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2619, '8309-1029-1985-4355', 208750513.000000, '2016-12-29 00:00:00', 'sleisted', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2620, '2221-0754-3973-1051', 204565936.000000, '2017-05-26 00:00:00', 'cgrichukhanovo2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2621, '4785-7858-5902-0580', 285042506.000000, '2016-12-12 00:00:00', 'edealeydp', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2622, '9452-0825-2091-3906', 406414920.000000, '2017-04-23 00:00:00', 'glegoode1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2623, '7790-6384-6955-0766', 197554502.000000, '2017-01-08 00:00:00', 'fvalentinettird', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2624, '2329-7925-9726-5030', 334074304.000000, '2016-08-07 00:00:00', 'lpatersonnn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2625, '6642-6674-6250-1202', 298538415.000000, '2016-10-15 00:00:00', 'gmelmothbg', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2626, '3925-5240-3610-2141', 377480259.000000, '2016-09-04 00:00:00', 'ohudel4e', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2627, '6415-4192-3179-9426', 186492437.000000, '2017-05-14 00:00:00', 'svauls4i', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2628, '5952-2699-9699-3113', 267501371.000000, '2016-08-01 00:00:00', 'dloudiankj', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2629, '0841-2249-8886-5338', 340032223.000000, '2017-05-23 00:00:00', 'wwebbeqg', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2630, '3304-1266-4460-0809', 230156076.000000, '2017-04-04 00:00:00', 'twenham82', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2631, '7591-2485-8429-7497', 250112167.000000, '2017-06-01 00:00:00', 'sleisted', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2632, '7872-2526-6619-2504', 321729132.000000, '2017-01-15 00:00:00', 'tenzleymz', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2633, '8208-5565-5813-1453', 403350641.000000, '2017-05-12 00:00:00', 'mmclaffertygm', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2634, '6761-5503-3356-1971', 420181369.000000, '2016-10-12 00:00:00', 'wshivlinr3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2635, '9446-5312-0194-9512', 379768813.000000, '2017-02-22 00:00:00', 'cgeraschnm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2636, '4593-9532-3041-7011', 427115350.000000, '2017-05-29 00:00:00', 'nbaythrop6f', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2637, '1373-6024-9204-8582', 319975775.000000, '2017-06-17 00:00:00', 'ldartnell8k', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2638, '9564-8786-5763-0311', 172028229.000000, '2017-06-28 00:00:00', 'chobben9a', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2639, '6889-0041-6232-5724', 237074899.000000, '2017-06-03 00:00:00', 'atarge3k', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2640, '4377-0106-3176-8044', 391094636.000000, '2016-09-12 00:00:00', 'hkryska6k', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2641, '0093-0717-7855-8621', 384909466.000000, '2017-03-20 00:00:00', 'hdufallh0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2642, '5498-8953-4099-5133', 193283078.000000, '2017-05-21 00:00:00', 'kfostersmithh4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2643, '4159-0519-3146-3812', 173463648.000000, '2016-10-21 00:00:00', 'fsirman9v', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2644, '2177-9204-5855-2340', 230765028.000000, '2017-01-21 00:00:00', 'oskipton96', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2645, '4408-7236-9916-1891', 302612185.000000, '2016-11-29 00:00:00', 'afromantfk', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2646, '0822-7068-9243-8891', 263241809.000000, '2017-02-22 00:00:00', 'aguirardinbz', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2647, '1780-2902-1963-8625', 267666073.000000, '2017-03-18 00:00:00', 'tchristauffour8a', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2648, '9704-9929-7178-8103', 371165199.000000, '2016-12-22 00:00:00', 'meastmondo5', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2649, '1778-8428-8990-5968', 281620719.000000, '2017-01-14 00:00:00', 'acurcherb5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2650, '0177-7899-6206-8106', 381946429.000000, '2017-02-04 00:00:00', 'dstoddly', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2651, '9899-9870-2438-3478', 341965445.000000, '2017-01-20 00:00:00', 'vgosnelllo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2652, '4170-9568-1904-9980', 369659972.000000, '2016-09-01 00:00:00', 'nbaythrop6f', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2653, '9827-9591-6662-0112', 333968888.000000, '2017-01-08 00:00:00', 'mroadse6', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2654, '9409-0563-8504-7287', 203204914.000000, '2016-08-17 00:00:00', 'jeydel37', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2655, '9811-1722-5045-0670', 156987654.000000, '2016-08-03 00:00:00', 'kcharsley7', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2656, '9350-0086-1238-0376', 344482319.000000, '2016-12-20 00:00:00', 'cedworthiee9', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2657, '3605-7164-4531-3983', 243712538.000000, '2017-05-11 00:00:00', 'jtoulamainpo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2658, '2387-4116-3699-0044', 218451745.000000, '2017-02-09 00:00:00', 'jabelwhite5e', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2659, '4327-3699-3991-5248', 153982226.000000, '2017-03-16 00:00:00', 'mpochethh', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2660, '8057-8052-0967-7029', 282176295.000000, '2016-10-14 00:00:00', 'mdibnahd9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2661, '2125-2796-8386-1777', 194104068.000000, '2016-11-14 00:00:00', 'sdevasqn', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2662, '7111-5132-7995-5089', 253794381.000000, '2016-08-06 00:00:00', 'jduigenano3', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2663, '4305-2519-0729-1255', 398617791.000000, '2017-02-17 00:00:00', 'koldknowl8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2664, '2819-7576-2967-7617', 191145085.000000, '2017-08-04 00:00:00', 'mcoucheaq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2665, '7600-5534-7912-7650', 198789752.000000, '2017-06-12 00:00:00', 'rmancejw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2666, '0031-0825-4207-7451', 220435539.000000, '2016-12-22 00:00:00', 'rsandifordji', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2667, '9494-1375-9599-2451', 373841988.000000, '2016-10-07 00:00:00', 'kdawdrybk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2668, '7785-2013-9754-1083', 229595142.000000, '2017-07-04 00:00:00', 'aaizikovitz9q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2669, '6690-3842-6103-9519', 155347758.000000, '2017-01-03 00:00:00', 'tnajerapk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2670, '2639-9433-6813-5967', 374286524.000000, '2017-03-29 00:00:00', 'squigah', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2671, '6646-0588-6217-9747', 296091163.000000, '2016-11-27 00:00:00', 'wlaurenty49', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2672, '6549-6805-4081-8635', 157644668.000000, '2016-08-31 00:00:00', 'cashtonhurstdr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2673, '8004-0166-8784-4683', 361578657.000000, '2017-08-02 00:00:00', 'shamill8q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2674, '8881-4291-1393-9206', 320949144.000000, '2017-06-13 00:00:00', 'po3n', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2675, '1628-4469-4254-4255', 227135613.000000, '2017-03-15 00:00:00', 'tminettekf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2676, '8552-0405-6197-9901', 180032884.000000, '2017-02-09 00:00:00', 'cwinder65', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2677, '9883-5961-6517-4010', 199939940.000000, '2016-11-08 00:00:00', 'ltemplemancy', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2678, '3084-3732-4361-0086', 314570648.000000, '2016-08-16 00:00:00', 'cashtonhurstdr', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2679, '0746-0674-7223-5619', 162263195.000000, '2016-11-30 00:00:00', 'cantat9d', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2680, '2280-1779-0471-5318', 319953591.000000, '2017-03-04 00:00:00', 'fgingell2s', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2681, '5545-1357-9636-3169', 265157954.000000, '2017-02-15 00:00:00', 'hdaffornem0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2682, '3583-8213-4143-9711', 351406882.000000, '2016-11-03 00:00:00', 'cschoffler27', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2683, '5081-7006-2463-0217', 188710765.000000, '2017-04-28 00:00:00', 'slabuschagne5', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2684, '0625-5789-0933-9728', 277696254.000000, '2017-01-03 00:00:00', 'rtoffaloniax', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2685, '0140-2787-6477-4524', 321473193.000000, '2017-05-20 00:00:00', 'nludwikiewiczir', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2686, '4821-3301-7746-1349', 173451564.000000, '2017-03-16 00:00:00', 'pbuttrumi0', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2687, '9606-1585-2060-8079', 197352142.000000, '2017-04-08 00:00:00', 'semneymr', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2688, '5467-3923-1765-7151', 287164412.000000, '2017-03-08 00:00:00', 'rcaslindn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2689, '0097-7698-8413-7348', 311968984.000000, '2016-12-21 00:00:00', 'bbattermy', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2690, '1508-2064-2026-7610', 283627171.000000, '2017-02-10 00:00:00', 'kpeschetgx', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2691, '0276-7149-2926-4746', 342964255.000000, '2017-02-13 00:00:00', 'gvaskovmw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2692, '5345-1932-3298-5325', 308894095.000000, '2017-02-09 00:00:00', 'cmollnar5d', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2693, '6387-3084-2819-5638', 215065373.000000, '2017-02-21 00:00:00', 'hdalrympleq5', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2694, '2374-2534-7359-2444', 295267755.000000, '2017-05-31 00:00:00', 'khadwenkb', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2695, '8263-6894-0909-0911', 449312945.000000, '2017-05-22 00:00:00', 'tditty5b', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2696, '3376-3270-3265-3518', 281737536.000000, '2017-08-02 00:00:00', 'aelwelld1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2697, '6941-1137-1293-6653', 174645121.000000, '2017-08-02 00:00:00', 'wnicklinsonhn', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2698, '0075-6185-1037-6321', 356976252.000000, '2017-07-21 00:00:00', 'bdjekovicnv', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2699, '1100-7332-6663-8295', 323773154.000000, '2017-07-03 00:00:00', 'do8c', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2700, '8580-4430-7584-2750', 378554193.000000, '2016-10-11 00:00:00', 'lerbi', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2701, '9392-5951-1261-6862', 285654413.000000, '2016-08-11 00:00:00', 'jlangmaid28', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2702, '6208-3887-9872-0419', 342591642.000000, '2017-03-22 00:00:00', 'omccardlef5', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2703, '5998-1286-0435-2887', 160182556.000000, '2017-03-05 00:00:00', 'ikingswelljn', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2704, '8722-1029-6046-2103', 348076727.000000, '2016-12-15 00:00:00', 'alubyay', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2705, '6876-3354-5583-1458', 271864870.000000, '2017-07-12 00:00:00', 'mmcgheemg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2706, '3915-5119-8398-0697', 161954249.000000, '2017-06-10 00:00:00', 'taizlewoodbm', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2707, '6879-9953-6602-9061', 390639422.000000, '2017-05-09 00:00:00', 'jabelwhite5e', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2708, '2998-6007-0135-7091', 360755150.000000, '2016-10-22 00:00:00', 'mchipps4t', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2709, '7016-8978-9924-1613', 436048579.000000, '2017-06-10 00:00:00', 'mbutson1c', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2710, '3535-2449-5558-7697', 438795351.000000, '2017-04-15 00:00:00', 'jnicklen30', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2711, '8000-2272-1003-6653', 396418336.000000, '2017-03-29 00:00:00', 'dtoopecv', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2712, '0941-9567-9911-0938', 217051673.000000, '2017-01-21 00:00:00', 'jblaxelandp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2713, '9865-7398-8744-4357', 359938680.000000, '2016-08-16 00:00:00', 'visaksond', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2714, '4348-8697-9298-2108', 309649743.000000, '2016-09-20 00:00:00', 'mhalfordba', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2715, '6953-0000-0012-2654', 276616019.000000, '2017-06-16 00:00:00', 'adrancepa', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2716, '9372-1718-0849-8844', 251653825.000000, '2017-07-09 00:00:00', 'tgowenad', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2717, '5374-2352-9131-4756', 359085201.000000, '2016-09-24 00:00:00', 'rbriston18', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2718, '4490-3980-7238-8700', 186706318.000000, '2016-09-30 00:00:00', 'ckeppinmf', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2719, '4759-7971-8874-1491', 303911356.000000, '2016-09-07 00:00:00', 'fwedmoreqb', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2720, '5414-2120-4147-4860', 336202643.000000, '2016-09-28 00:00:00', 'lalliotqt', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2721, '6771-5490-2874-7421', 379147625.000000, '2017-05-29 00:00:00', 'ajustmi', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2722, '6130-3140-1930-7167', 397900223.000000, '2016-09-14 00:00:00', 'tchristauffour8a', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2723, '7671-7317-0267-7964', 255597520.000000, '2016-09-08 00:00:00', 'rthackerayhy', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2724, '1679-2509-6968-7377', 235356629.000000, '2016-08-11 00:00:00', 'rmancejw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2725, '7366-7385-3876-8415', 240997497.000000, '2016-08-12 00:00:00', 'cfiennes1t', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2726, '6735-0858-7744-7994', 198891486.000000, '2016-10-03 00:00:00', 'sbeldam8d', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2727, '9047-7506-0162-0489', 270213713.000000, '2017-01-15 00:00:00', 'dberthonkk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2728, '7881-2895-3447-1545', 351790959.000000, '2016-12-07 00:00:00', 'pfeltoego', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2729, '1244-3751-3519-7016', 445123850.000000, '2017-08-01 00:00:00', 'sgrigautcz', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2730, '7800-5498-7867-5837', 380700390.000000, '2017-04-29 00:00:00', 'ldeds', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2731, '1218-5597-4263-9081', 410552918.000000, '2017-01-10 00:00:00', 'pbuttrumi0', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2732, '5123-5612-7316-1987', 441763526.000000, '2017-03-21 00:00:00', 'sizzetthc', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2733, '0605-9991-1349-8896', 294317837.000000, '2016-09-14 00:00:00', 'csimeonc5', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2734, '6024-2414-7844-5037', 207314818.000000, '2017-02-11 00:00:00', 'kgosselin6e', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2735, '3564-5733-3113-4933', 342170612.000000, '2017-02-06 00:00:00', 'mkochslz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2736, '3163-6133-3780-5137', 230028992.000000, '2016-09-20 00:00:00', 'bcowdryn8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2737, '7629-4189-1211-5218', 305230551.000000, '2017-02-02 00:00:00', 'amatussovw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2738, '2370-4863-9564-5049', 185454666.000000, '2016-11-16 00:00:00', 'ajeannardbe', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2739, '6703-6438-5781-3618', 441823261.000000, '2017-06-22 00:00:00', 'testoile4q', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2740, '9512-2858-0859-3287', 335441785.000000, '2017-07-03 00:00:00', 'mlavies8n', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2741, '7168-3838-8848-0614', 152524025.000000, '2016-09-14 00:00:00', 'mmcgheemg', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2742, '2425-7395-8704-0178', 328764601.000000, '2016-08-24 00:00:00', 'qtilll6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2743, '3118-9370-9608-0660', 268902708.000000, '2017-03-03 00:00:00', 'mcassinlv', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2744, '0714-1131-7491-7867', 303027768.000000, '2016-12-18 00:00:00', 'ecarlesiib', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2745, '3787-9057-2673-4768', 176129476.000000, '2017-05-15 00:00:00', 'zschusterlft', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2746, '6926-2835-3378-2241', 445820027.000000, '2017-04-29 00:00:00', 'bbiasi99', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2747, '6927-8165-6542-7138', 209317516.000000, '2017-08-05 00:00:00', 'dgethingsaf', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2748, '6288-7006-5475-6661', 395106665.000000, '2017-02-06 00:00:00', 'cjzak9p', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2749, '1832-9622-2825-4224', 171539535.000000, '2016-08-30 00:00:00', 'rdamantcw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2750, '1232-4421-2594-5281', 279263633.000000, '2017-07-17 00:00:00', 'gantyshevnc', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2751, '1486-3459-0435-3155', 414816188.000000, '2016-11-06 00:00:00', 'pswane61', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2752, '8910-8488-8040-7169', 437226877.000000, '2016-10-26 00:00:00', 'uledwardm8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2753, '6243-5359-5834-3643', 325129846.000000, '2017-03-11 00:00:00', 'gsurman8t', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2754, '3349-8388-9044-8651', 291158773.000000, '2016-11-22 00:00:00', 'edicheob', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2755, '3030-5344-0883-5346', 440084891.000000, '2017-07-16 00:00:00', 'scoultl4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2756, '3652-8402-2084-3744', 223976286.000000, '2017-04-07 00:00:00', 'fmathiassen7l', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2757, '1283-8610-4212-9730', 351293731.000000, '2017-07-10 00:00:00', 'fcorkelgq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2758, '9634-2056-2795-7015', 303214970.000000, '2016-08-11 00:00:00', 'tpoter5r', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2759, '5092-0727-0054-6347', 161667725.000000, '2016-12-28 00:00:00', 'cminto7c', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2760, '7589-0471-6735-5401', 222567122.000000, '2017-07-17 00:00:00', 'kcocklingp4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2761, '7327-6841-6103-5107', 221540974.000000, '2017-01-28 00:00:00', 'gprendergast1u', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2762, '7998-0816-9249-5992', 279388426.000000, '2017-02-16 00:00:00', 'amallatrattm2', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2763, '9156-2306-0183-0385', 219142727.000000, '2016-11-01 00:00:00', 'lsemirazfc', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2764, '2379-6060-8267-7139', 173224394.000000, '2016-08-29 00:00:00', 'wburroughes54', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2765, '1772-4265-0104-8486', 219736338.000000, '2016-11-08 00:00:00', 'bforsdicke8v', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2766, '5835-9233-7689-1111', 224937401.000000, '2017-01-11 00:00:00', 'jlangmaid28', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2767, '2109-5322-2196-3482', 175286921.000000, '2016-09-10 00:00:00', 'standerkv', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2768, '8602-7362-1082-6366', 265633611.000000, '2016-10-20 00:00:00', 'sbarizeretl1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2769, '6576-6280-8889-9108', 263388765.000000, '2017-05-11 00:00:00', 'rroddanlt', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2770, '7056-7918-1988-2836', 405605512.000000, '2016-10-30 00:00:00', 'gantyshevnc', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2771, '4709-7969-4885-5187', 273823184.000000, '2017-04-23 00:00:00', 'dgerkenskq', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2772, '8327-1459-3640-6015', 254365575.000000, '2016-09-16 00:00:00', 'affoulkes83', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2773, '9261-3382-3016-6082', 395593459.000000, '2017-07-08 00:00:00', 'aalanbrooke3q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2774, '2491-7738-6169-4478', 167590851.000000, '2016-09-05 00:00:00', 'rbriars95', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2775, '2543-2609-9528-0688', 328781801.000000, '2016-12-03 00:00:00', 'mgilkison8m', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2776, '0077-8382-6894-1833', 390236284.000000, '2017-02-24 00:00:00', 'krichichit', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2777, '6186-9891-1392-0544', 293921244.000000, '2017-04-11 00:00:00', 'cnowakowskiiw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2778, '0207-6599-6207-7293', 166212382.000000, '2017-01-13 00:00:00', 'blosbie3w', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2779, '6847-4825-8553-5681', 227857987.000000, '2017-01-06 00:00:00', 'tpoter5r', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2780, '7786-2488-0114-3528', 400040719.000000, '2016-12-21 00:00:00', 'pjackmanqs', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2781, '1293-6124-3978-4095', 272685514.000000, '2017-04-25 00:00:00', 'abengallke', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2782, '6555-6816-0646-2682', 241492517.000000, '2017-04-30 00:00:00', 'ajeannardbe', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2783, '9924-9845-7043-6223', 272639926.000000, '2017-06-14 00:00:00', 'gmorbey44', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2784, '7923-5977-0907-5796', 317887559.000000, '2016-08-07 00:00:00', 'cnewbornd7', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2785, '0560-4661-1372-3656', 236855547.000000, '2016-11-15 00:00:00', 'bwickwarthg8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2786, '5500-1286-3789-0175', 368245220.000000, '2017-04-05 00:00:00', 'nspieghtnt', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2787, '2612-5828-0172-4289', 429240434.000000, '2017-05-02 00:00:00', 'khabbershonb6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2788, '4990-7591-5046-9079', 318043547.000000, '2016-08-09 00:00:00', 'tcoffeerp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2789, '0684-6111-7709-1157', 353099245.000000, '2017-03-25 00:00:00', 'lcantrilleq', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2790, '0303-9744-5598-1034', 296170835.000000, '2017-03-24 00:00:00', 'noliveirafs', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2791, '1143-1930-0572-7289', 357994922.000000, '2017-07-24 00:00:00', 'cthoroldfe', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2792, '5213-1946-6403-3553', 333222751.000000, '2017-07-16 00:00:00', 'tdalmanjd', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2793, '5832-6937-3216-6329', 314458738.000000, '2017-03-15 00:00:00', 'ulucience', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2794, '9218-1566-1068-6049', 190170981.000000, '2017-02-09 00:00:00', 'tdalmanjd', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2795, '8711-8195-4783-1092', 352847391.000000, '2017-01-31 00:00:00', 'nhugeninjx', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2796, '3232-3396-8859-4945', 419604214.000000, '2016-12-21 00:00:00', 'rmeasham3r', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2797, '4551-2589-7606-5608', 392179146.000000, '2016-11-10 00:00:00', 'rbriars95', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2798, '0798-4948-4656-4453', 164072261.000000, '2017-05-06 00:00:00', 'pdoig70', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2799, '8284-5047-3214-2991', 199062496.000000, '2016-11-12 00:00:00', 'psloraes', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2800, '3891-5908-7556-6405', 260339813.000000, '2016-12-29 00:00:00', 'rescotmx', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2801, '8950-2285-5040-4032', 160053599.000000, '2016-09-14 00:00:00', 'bdjekovicnv', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2802, '5166-2374-5347-4160', 278080579.000000, '2017-02-26 00:00:00', 'cfishpond2a', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2803, '0495-0274-6737-9516', 345705268.000000, '2017-07-02 00:00:00', 'rniccollsbu', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2804, '2792-9059-5930-6484', 326533587.000000, '2017-05-09 00:00:00', 'aosbanjr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2805, '3897-2818-7764-7654', 200221214.000000, '2017-05-22 00:00:00', 'kcocklingp4', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2806, '8728-0284-9812-6524', 384762734.000000, '2017-03-16 00:00:00', 'lchristal3b', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2807, '1810-2868-6592-1860', 290244307.000000, '2017-02-02 00:00:00', 'lhurley5a', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2808, '2226-7529-2167-0371', 242215820.000000, '2017-06-17 00:00:00', 'tmcvityhe', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2809, '2864-4811-5832-3298', 303601814.000000, '2017-04-03 00:00:00', 'arichiek6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2810, '0519-8443-6363-4791', 225305314.000000, '2017-02-13 00:00:00', 'mcassinlv', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2811, '5568-2696-5810-0516', 412115284.000000, '2017-07-02 00:00:00', 'fhamnerje', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2812, '6904-6818-2252-3788', 428690962.000000, '2017-06-06 00:00:00', 'wjeaycock4o', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2813, '8438-2972-3579-8814', 183141831.000000, '2017-03-09 00:00:00', 'rchippingf3', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2814, '2705-5302-1866-9530', 418454459.000000, '2016-10-22 00:00:00', 'cmcgerraghtydx', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2815, '8351-7638-6418-0664', 327887573.000000, '2016-08-25 00:00:00', 'eredolfirg', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2816, '2952-6640-6879-5318', 185724826.000000, '2017-07-23 00:00:00', 'ddeemingdo', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2817, '9955-6247-5740-6265', 281900299.000000, '2016-12-31 00:00:00', 'fbroome5i', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2818, '1006-8363-7959-5345', 216581165.000000, '2016-11-06 00:00:00', 'jbuttingq4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2819, '4152-6436-1853-4550', 341394702.000000, '2017-01-15 00:00:00', 'mwolstenholme2r', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2820, '8192-2341-2023-3195', 192870748.000000, '2016-10-13 00:00:00', 'cshobbrook7e', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2821, '5146-4727-1765-5050', 258571770.000000, '2017-02-21 00:00:00', 'jbuttingq4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2822, '1212-1898-2182-5009', 334126924.000000, '2016-10-01 00:00:00', 'kdaubney1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2823, '4469-1115-0179-3752', 207689268.000000, '2016-09-27 00:00:00', 'ejonascd', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2824, '3578-5937-5577-4200', 179930665.000000, '2017-02-01 00:00:00', 'slumsdall8w', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2825, '7603-4214-2216-1711', 204698596.000000, '2016-11-22 00:00:00', 'fkenrickj1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2826, '3231-5665-9336-4930', 192071782.000000, '2017-07-11 00:00:00', 'apenricenh', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2827, '5706-5268-7517-7328', 287591459.000000, '2017-03-05 00:00:00', 'cvickersm7', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2828, '0500-8267-0385-3204', 197279445.000000, '2016-10-15 00:00:00', 'jcullingford1q', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2829, '4041-1655-5923-0729', 419077570.000000, '2017-03-30 00:00:00', 'sheckle9m', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2830, '8376-7939-9428-9693', 327776112.000000, '2017-02-15 00:00:00', 'rcholominju', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2831, '6669-0305-6209-5818', 404849804.000000, '2016-10-24 00:00:00', 'rmogglecj', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2832, '9191-8786-5106-0667', 289721207.000000, '2017-01-18 00:00:00', 'gduffrie2w', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2833, '6949-2008-3748-8577', 416256998.000000, '2017-05-23 00:00:00', 'ayielding6m', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2834, '1895-4646-2215-5779', 283046671.000000, '2016-10-30 00:00:00', 'slabuschagne5', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2835, '3938-0252-3933-7528', 411821867.000000, '2017-02-01 00:00:00', 'acossum40', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2836, '5255-9094-5380-8858', 328818970.000000, '2017-06-10 00:00:00', 'ckocklw', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2837, '7213-3694-2680-3233', 180000594.000000, '2017-02-17 00:00:00', 'csetfordls', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2838, '5063-8232-6239-0150', 449320994.000000, '2017-05-11 00:00:00', 'nwalsh6l', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2839, '6914-6780-2252-4531', 374417004.000000, '2016-10-04 00:00:00', 'lmcquorkelex', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2840, '9237-4423-9181-6079', 232702611.000000, '2016-10-06 00:00:00', 'motridgeky', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2841, '6846-6981-4048-7296', 343353751.000000, '2017-05-16 00:00:00', 'igerholdpf', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2842, '8970-0470-8363-0744', 349476672.000000, '2017-06-26 00:00:00', 'jmackettn2', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2843, '1259-1754-5933-9904', 348803909.000000, '2016-12-15 00:00:00', 'lkinneally1x', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2844, '6736-4528-6431-4990', 254253868.000000, '2017-05-22 00:00:00', 'aguirardinbz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2845, '9603-6566-4780-2484', 201307479.000000, '2016-10-03 00:00:00', 'fmutimer59', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2846, '4303-2080-5179-6157', 188711068.000000, '2017-05-14 00:00:00', 'bstutelyqm', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2847, '0026-2816-9564-1013', 421357544.000000, '2016-11-27 00:00:00', 'aanslow3s', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2848, '2437-1576-3404-9908', 357547395.000000, '2016-10-09 00:00:00', 'wdedrickjy', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2849, '7644-6681-1066-9493', 163260900.000000, '2017-02-09 00:00:00', 'cashtonhurstdr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2850, '9027-9750-8145-5379', 152246852.000000, '2017-01-27 00:00:00', 'ddjokovicnw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2851, '8029-3357-1321-2734', 270252955.000000, '2016-11-27 00:00:00', 'cfishpond2a', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2852, '8447-8591-4374-9287', 232395529.000000, '2017-07-07 00:00:00', 'gprendergast1u', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2853, '9956-5857-4936-7706', 259868172.000000, '2017-06-30 00:00:00', 'lvieyraqp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2854, '7029-1545-0892-4400', 402991903.000000, '2016-08-21 00:00:00', 'abengallke', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2855, '7668-8112-2077-8420', 164029646.000000, '2017-03-24 00:00:00', 'rlowfr', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2856, '4100-6594-6717-1670', 200377075.000000, '2016-11-14 00:00:00', 'jcometti5k', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2857, '0947-0978-6525-5862', 437151104.000000, '2016-11-03 00:00:00', 'jboalerej', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2858, '5461-3866-0547-6212', 303708785.000000, '2016-11-08 00:00:00', 'cnewbornd7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2859, '3779-1660-9901-5439', 342663762.000000, '2017-03-21 00:00:00', 'edealeydp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2860, '3202-8785-7610-1620', 427481131.000000, '2017-02-20 00:00:00', 'dcorrisong0', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2861, '7634-2860-1941-8213', 153626985.000000, '2017-06-28 00:00:00', 'rgarnarbn', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2862, '8255-9599-2397-2235', 251725734.000000, '2016-11-26 00:00:00', 'brentoulan', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2863, '2691-9297-6444-7373', 321407447.000000, '2017-04-09 00:00:00', 'lpetrello1l', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2864, '7553-1142-5366-4335', 410818321.000000, '2016-12-21 00:00:00', 'obreadmorehb', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2865, '4314-0768-0987-6657', 191440147.000000, '2017-03-10 00:00:00', 'aanlaynu', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2866, '4767-9095-0546-9814', 408523122.000000, '2016-09-20 00:00:00', 'rhazley4', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2867, '3985-9819-3116-5865', 195861191.000000, '2017-07-21 00:00:00', 'slabuschagne5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2868, '7847-2436-8417-7320', 235189190.000000, '2017-04-05 00:00:00', 'ablevinii', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2869, '5330-5848-7591-3934', 352792754.000000, '2017-03-03 00:00:00', 'lpatersonnn', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2870, '5572-5438-7645-6397', 297729885.000000, '2016-12-16 00:00:00', 'pprobyncg', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2871, '9333-5118-1529-7984', 295462449.000000, '2017-04-12 00:00:00', 'amatussovw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2872, '5759-8945-6212-8937', 198614892.000000, '2017-06-10 00:00:00', 'atrent97', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2873, '8395-3917-3255-9601', 338693504.000000, '2017-07-14 00:00:00', 'dstrowlgerz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2874, '4131-2373-0165-9478', 313459152.000000, '2017-01-05 00:00:00', 'agladebeckjo', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2875, '5033-5983-6056-9695', 202565945.000000, '2016-08-30 00:00:00', 'sditchett6c', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2876, '0960-7222-9969-6257', 208180448.000000, '2017-07-05 00:00:00', 'blej', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2877, '5486-6285-1590-0991', 167676377.000000, '2017-03-01 00:00:00', 'scoultl4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2878, '4698-6390-5786-6178', 340593688.000000, '2017-07-01 00:00:00', 'kcornejobs', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2879, '4342-2780-7568-5225', 169404666.000000, '2017-01-02 00:00:00', 'pguilletonph', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2880, '7518-6779-3429-9920', 372813696.000000, '2017-07-04 00:00:00', 'avedeniktov78', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2881, '3088-3945-1440-3580', 164203799.000000, '2016-10-10 00:00:00', 'dhyettme', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2882, '4408-0595-7155-9372', 440208760.000000, '2016-08-12 00:00:00', 'gcaneg5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2883, '1033-2607-6812-4756', 330296106.000000, '2017-07-29 00:00:00', 'spashler2m', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2884, '3351-8284-2471-0010', 411166561.000000, '2016-10-06 00:00:00', 'acurcherb5', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2885, '0634-8834-4770-5595', 259986477.000000, '2017-03-07 00:00:00', 'cfiennes1t', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2886, '1208-7236-2812-7101', 381174261.000000, '2016-12-13 00:00:00', 'mzmitruk1r', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2887, '7122-1814-6549-4560', 223912095.000000, '2017-04-03 00:00:00', 'dtitteringtonbw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2888, '6768-3643-4256-4220', 235601926.000000, '2017-03-10 00:00:00', 'ggladtbach4v', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2889, '8591-9284-0584-6791', 289801928.000000, '2017-01-15 00:00:00', 'levittsrk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2890, '6777-1760-8793-1361', 316688718.000000, '2017-05-17 00:00:00', 'ckeppinmf', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2891, '3523-3487-9241-1570', 230384051.000000, '2016-11-02 00:00:00', 'ethirkettleij', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2892, '2917-8025-4648-5433', 175870581.000000, '2017-03-06 00:00:00', 'ufowler46', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2893, '3322-4897-9107-1728', 412032745.000000, '2016-08-14 00:00:00', 'dlongridgehp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2894, '1715-3197-2111-3732', 326023915.000000, '2016-08-13 00:00:00', 'gmernerep', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2895, '6097-8025-5355-8835', 410829400.000000, '2017-06-23 00:00:00', 'mgunthorpgy', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2896, '0608-5823-5376-5827', 382975934.000000, '2017-01-04 00:00:00', 'rlansberryq6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2897, '1715-3747-1720-3476', 355602395.000000, '2017-02-12 00:00:00', 'jlangmaid28', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2898, '6190-5949-0687-4935', 431255643.000000, '2016-09-18 00:00:00', 'pfeltoego', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2899, '9021-7503-0770-8770', 267345446.000000, '2016-10-12 00:00:00', 'cabramzon85', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2900, '4290-0070-6740-7625', 354324975.000000, '2017-02-27 00:00:00', 'vjosefhl', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2901, '0666-9829-4314-5827', 169715289.000000, '2016-09-05 00:00:00', 'lmccalisterk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2902, '9627-0264-8010-2775', 300817636.000000, '2017-06-23 00:00:00', 'dpochind4', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2903, '9663-7399-2659-9823', 416817050.000000, '2017-06-23 00:00:00', 'dtitteringtonbw', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2904, '3855-6910-5022-2536', 367747865.000000, '2016-09-01 00:00:00', 'amcaughtryj2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2905, '4279-6890-8395-1948', 156925712.000000, '2016-10-11 00:00:00', 'jivashinnikovkz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2906, '6435-6102-6448-7735', 317205368.000000, '2017-06-29 00:00:00', 'shalliburton1d', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2907, '6311-4328-5738-9003', 276607347.000000, '2017-04-14 00:00:00', 'edealeydp', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2908, '2848-2744-0190-5423', 237850187.000000, '2016-08-07 00:00:00', 'tditty5b', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2909, '8873-8169-5351-4597', 412128120.000000, '2016-08-22 00:00:00', 'callbrook0', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2910, '4043-0854-4270-8728', 176865137.000000, '2017-02-26 00:00:00', 'ldeloozer6', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2911, '8474-4826-4105-1942', 260157011.000000, '2017-03-13 00:00:00', 'mfarndaleff', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2912, '1695-8142-0494-1325', 377518915.000000, '2017-07-08 00:00:00', 'lerbi', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2913, '8949-2140-6063-1411', 263779765.000000, '2016-09-06 00:00:00', 'cdohrmann6s', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2914, '4054-9689-4325-5539', 277424684.000000, '2016-09-21 00:00:00', 'lsmoutena7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2915, '2555-8595-1981-5035', 232030941.000000, '2017-02-26 00:00:00', 'sgrigautcz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2916, '8605-4497-9671-2082', 244658474.000000, '2017-06-14 00:00:00', 'fkenrickj1', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2917, '5244-2130-6489-3790', 329600742.000000, '2017-01-06 00:00:00', 'tollerf2', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2918, '4928-3149-3924-5463', 436807394.000000, '2016-09-26 00:00:00', 'jpicheford3h', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2919, '5005-5947-1669-7433', 413751107.000000, '2016-08-04 00:00:00', 'mkochslz', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2920, '3647-6351-8394-2616', 270942971.000000, '2017-04-23 00:00:00', 'zingleson4y', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2921, '6891-4271-1973-2374', 188422555.000000, '2017-02-05 00:00:00', 'asummerleeb3', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2922, '9450-2942-2446-0134', 175904073.000000, '2017-06-01 00:00:00', 'gparrattih', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2923, '6492-8933-7311-0833', 389339810.000000, '2017-01-12 00:00:00', 'acastillagr', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2924, '5466-0802-3043-9209', 177527534.000000, '2017-04-21 00:00:00', 'jyokleylx', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2925, '3000-3455-2371-2202', 181636359.000000, '2016-09-01 00:00:00', 'akunzelr', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2926, '6129-3758-3370-1064', 163737593.000000, '2017-03-24 00:00:00', 'bdumingoscf', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2927, '4951-5075-6890-1921', 446378264.000000, '2016-10-03 00:00:00', 'lmccalisterk', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2928, '8808-7037-4636-5458', 440739383.000000, '2017-06-18 00:00:00', 'amcaughtryj2', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2929, '8342-8916-6091-0997', 261475232.000000, '2017-04-26 00:00:00', 'smenureil', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2930, '4102-3571-7578-9316', 393497748.000000, '2017-05-28 00:00:00', 'lcasbolt8', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2931, '6007-5744-6350-7012', 397957608.000000, '2017-08-05 00:00:00', 'mvelarealoy', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2932, '7550-2771-7686-5389', 215037737.000000, '2017-04-26 00:00:00', 'ftwentyman2b', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2933, '8624-3519-7073-8889', 376929808.000000, '2017-07-01 00:00:00', 'obreadmorehb', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2934, '4951-7728-4865-7119', 391874163.000000, '2017-06-29 00:00:00', 'dmontegs', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2935, '4210-9603-8763-2613', 204452189.000000, '2016-11-28 00:00:00', 'emarien57', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2936, '0453-2833-3985-5714', 312718535.000000, '2016-11-08 00:00:00', 'sleonards7t', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2937, '3215-9131-3810-9645', 196648463.000000, '2016-11-24 00:00:00', 'tbullivantic', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2938, '9437-9631-0215-9569', 418181843.000000, '2016-10-19 00:00:00', 'jyokleylx', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2939, '6111-8936-1243-3669', 442975568.000000, '2016-08-08 00:00:00', 'wdedrickjy', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2940, '4913-8360-5886-2583', 383121641.000000, '2017-06-02 00:00:00', 'frylancel7', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2941, '1630-2763-2918-1826', 309298888.000000, '2017-06-19 00:00:00', 'zwhiteson6y', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2942, '0467-4180-3844-5016', 273258020.000000, '2016-10-13 00:00:00', 'msharphurstqo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2943, '6711-5787-2026-3049', 411079101.000000, '2017-06-21 00:00:00', 'mbeddowsg9', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2944, '8016-7570-0156-5732', 370092956.000000, '2016-12-31 00:00:00', 'abreenk3', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2945, '5312-6857-8329-4307', 213289735.000000, '2016-12-16 00:00:00', 'ikingswelljn', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2946, '8492-1601-9003-0722', 297720322.000000, '2017-03-19 00:00:00', 'gparrattih', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2947, '1850-5689-4698-5360', 323448126.000000, '2016-09-09 00:00:00', 'mwiddecombehw', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2948, '5549-7201-3406-2052', 240930928.000000, '2017-03-26 00:00:00', 'amcaughtryj2', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2949, '2145-0817-1806-5619', 415946776.000000, '2016-11-21 00:00:00', 'lbrisbane9x', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2950, '3386-4862-5982-2134', 337980497.000000, '2017-01-11 00:00:00', 'wjeaycock4o', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2951, '8133-2840-6789-4226', 448277764.000000, '2016-09-08 00:00:00', 'sthebeaudbp', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2952, '4207-6401-0561-6908', 420540951.000000, '2017-06-16 00:00:00', 'aphillips', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2953, '0918-4472-2848-7283', 447937680.000000, '2017-02-09 00:00:00', 'gsurman8t', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2954, '1747-5102-2907-6287', 264281080.000000, '2017-03-14 00:00:00', 'lcasbolt8', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2955, '0409-6333-1242-5641', 390747988.000000, '2017-04-09 00:00:00', 'vgreen9k', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2956, '2301-0035-4173-7602', 394437946.000000, '2017-06-09 00:00:00', 'vpresswellis', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2957, '0972-2060-7570-4742', 164074298.000000, '2016-11-28 00:00:00', 'taizlewoodbm', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2958, '8400-7278-4743-0412', 436769036.000000, '2016-12-15 00:00:00', 'santoninkp', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2959, '1630-0325-3078-1771', 343461258.000000, '2016-11-30 00:00:00', 'pkleingrub4f', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2960, '9762-0319-9292-3843', 309946389.000000, '2017-03-02 00:00:00', 'mkochslz', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2961, '3055-9395-0551-1743', 434402159.000000, '2017-02-20 00:00:00', 'kwickey7w', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2962, '3690-3934-5226-0835', 222239986.000000, '2016-10-08 00:00:00', 'cusborn1m', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2963, '6618-0714-7209-2612', 211043228.000000, '2017-04-01 00:00:00', 'epicktonpr', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2964, '8312-8004-6508-8521', 161092362.000000, '2016-12-20 00:00:00', 'tsidnell2l', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2965, '6475-6514-2453-4835', 239099699.000000, '2017-05-31 00:00:00', 'ckeppinmf', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2966, '8378-6768-8364-3911', 272610428.000000, '2017-02-19 00:00:00', 'pkleingrub4f', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2967, '4005-4766-2723-3197', 287194754.000000, '2017-06-30 00:00:00', 'jmackettn2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2968, '0687-8276-6997-1825', 426388127.000000, '2016-10-01 00:00:00', 'jbrookfield9g', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2969, '7990-8986-5243-0174', 373188223.000000, '2016-12-04 00:00:00', 'cmeechou', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2970, '6362-1048-2724-2482', 353225023.000000, '2017-01-04 00:00:00', 'affoulkes83', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2971, '1103-8690-6162-9912', 300067840.000000, '2017-05-28 00:00:00', 'jpicheford3h', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2972, '9312-3571-8136-5150', 341948636.000000, '2017-02-05 00:00:00', 'gduffrie2w', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2973, '2541-3883-4415-5470', 395369566.000000, '2017-06-20 00:00:00', 'yalabone15', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2974, '1155-5855-4355-6453', 167474069.000000, '2017-06-09 00:00:00', 'aadamoco', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2975, '0481-3816-5327-8449', 271602659.000000, '2016-08-28 00:00:00', 'hbrearley6v', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2976, '7768-6079-3106-5111', 363952396.000000, '2016-10-05 00:00:00', 'cklammtf0', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2977, '9976-0588-1601-7673', 449642926.000000, '2017-03-21 00:00:00', 'ayielding6m', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2978, '9463-7248-4089-1277', 290312061.000000, '2016-11-26 00:00:00', 'dpaulsener', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2979, '5537-9720-1139-0893', 385347774.000000, '2017-02-08 00:00:00', 'tsiggersrj', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2980, '4478-6872-9766-2388', 383570075.000000, '2017-01-01 00:00:00', 'kwyvill52', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2981, '5737-9930-3751-6329', 176745366.000000, '2016-11-17 00:00:00', 'bbattermy', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2982, '4465-3058-5886-7856', 215796068.000000, '2017-03-26 00:00:00', 'testoile4q', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2983, '8745-2834-9122-8299', 366916616.000000, '2016-09-23 00:00:00', 'smellh1', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2984, '3562-0267-9135-6995', 154589587.000000, '2017-07-15 00:00:00', 'mtorriem1', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2985, '5830-2732-8025-4631', 287008849.000000, '2016-12-05 00:00:00', 'agladebeckjo', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2986, '7306-9992-1336-8948', 347939950.000000, '2016-12-24 00:00:00', 'rlansberryq6', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2987, '1082-9900-0565-9255', 268957972.000000, '2016-12-01 00:00:00', 'bmedcraft4c', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2988, '8466-9796-9588-7753', 169839726.000000, '2016-10-21 00:00:00', 'mhinzernk', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2989, '0356-9831-7390-6579', 222243568.000000, '2017-06-13 00:00:00', 'mfayter67', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2990, '8468-1656-5592-5265', 314737829.000000, '2017-05-28 00:00:00', 'gkeoghane2o', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2991, '9213-9472-8334-0889', 151569915.000000, '2017-03-23 00:00:00', 'tmajorei', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2992, '8721-1513-2509-7767', 205088487.000000, '2016-08-04 00:00:00', 'kgaytherhu', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2993, '3546-4779-2181-9597', 435694556.000000, '2016-10-19 00:00:00', 'adrancepa', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2994, '4568-2630-8285-9226', 341637700.000000, '2017-03-26 00:00:00', 'pnation8l', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2995, '8682-7001-7740-8714', 286308927.000000, '2016-12-03 00:00:00', 'jaleshkov42', 2, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2996, '0403-3112-9590-3201', 424912598.000000, '2017-02-16 00:00:00', 'mdanielsencc', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2997, '2018-6394-5751-8840', 303565767.000000, '2017-04-16 00:00:00', 'cgrichukhanovo2', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2998, '7572-5956-2301-9837', 233038604.000000, '2017-06-29 00:00:00', 'fmagrane76', 3, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (2999, '2138-4325-5167-1782', 305470903.000000, '2016-10-02 00:00:00', 'rbabb31', 1, NULL, NULL, NULL, NULL);
INSERT INTO transaccion VALUES (3000, '5844-8348-1804-8665', 157419054.000000, '2017-02-26 00:00:00', 'kwalterq0', 2, NULL, NULL, NULL, NULL);


--
-- TOC entry 2332 (class 0 OID 0)
-- Dependencies: 192
-- Name: transaccion_tran_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('transaccion_tran_id_seq', 3000, true);


--
-- TOC entry 2294 (class 0 OID 35178)
-- Dependencies: 194
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO usuario VALUES ('kdaubney1', 'ux9zOncZQWN', 2, 'Karina D''Aubney', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('aarnett2', 'YSambLoUS', 3, 'Aguste Arnett', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('nsnaith3', 'A6nJK4b', 4, 'Nanon Snaith', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rhazley4', '4u9CYYl4p', 5, 'Rosaleen Hazley', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('slabuschagne5', '8SXvuUWeChoS', 6, 'Shell Labuschagne', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bmatousek6', 'fKLuKUubQ6', 7, 'Bank Matousek', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('kcharsley7', 'A3zVty', 8, 'Karilynn Charsley', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lcasbolt8', 'm8hyS01fU', 9, 'Lyndsey Casbolt', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('aelgee9', 'l2BdJhdWdwyQ', 10, 'Alma Elgee', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bconnerlya', 'p8X4lbLzR', 11, 'Byrann Connerly', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('nmcgeneayb', 'N1nGZUpRNNO', 12, 'Nichole McGeneay', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('alec', '0IF8dofi4USw', 13, 'Aarika Le Sarr', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('visaksond', 'qkZbWsLYdwgR', 14, 'Verina Isakson', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mtollmachee', 'v0pub1H4dRuo', 15, 'Muire Tollmache', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mswindenf', 'fHM1u2BBvPb', 16, 'Mildrid Swinden', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kyouleg', 'dEkeEbZRnf', 17, 'Kessia Youle', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('jgriswaiteh', 'QxP09VqFnf9', 18, 'Jessika Griswaite', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lerbi', 'U0hG3U', 19, 'Leshia Erb', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('blej', 'zf2kru', 20, 'Bennett Le Huquet', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lmccalisterk', 'kBNRDBwjCc', 21, 'Lori McCalister', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('chamnerl', 'EsFUeviVVr66', 22, 'Chucho Hamner', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('reilersm', '7sT9AyUx', 23, 'Rafa Eilers', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mtenneyn', '8i1JVji9ARR', 24, 'Marlane Tenney', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bwitseyo', '5NarwM', 25, 'Bary Witsey', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('jblaxelandp', '2BSoE3gz', 26, 'Jorge Blaxeland', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dhuzzeyq', 'SIJYwH', 27, 'David Huzzey', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cbailesr', 'RRp2DZu', 28, 'Colet Bailes', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('aphillips', 'FDavaxuZ3nPe', 29, 'Adrien Phillip', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('krichichit', 'fdfkUv', 30, 'Kellie Richichi', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tchelamu', 'RcJDndr94pgo', 31, 'Thane Chelam', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cautiev', 'MxwqB7q25hU', 32, 'Creighton Autie', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('amatussovw', '428Im3bY4', 33, 'Annmarie Matussov', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('nfedderx', 'HDMiIWYJd', 34, 'Nilson Fedder', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bmcilraithy', 'jzI0TrEGfE', 35, 'Bengt McIlraith', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('dstrowlgerz', '8McFG7u', 36, 'Dorolice Strowlger', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('adoogood10', 'ADM8GaK57g', 37, 'Alida Doogood', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rdominetti11', 'OclWgp', 38, 'Roxane Dominetti', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dolahy12', 'EzNm59S', 39, 'Dulcine O''Lahy', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ghowes13', 'Or6Qg58Om', 40, 'Gennifer Howes', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dbever14', 'VCFn3vE', 41, 'Danielle Bever', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('yalabone15', 'nBnyyxnj6I', 42, 'Yvor Alabone', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('vbenez16', 'oWsm3w', 43, 'Vasilis Benez', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kgrenshields17', 'rnbDkJM', 44, 'Kathrine Grenshields', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rbriston18', 'GCBXMT', 45, 'Ros Briston', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('dswinyard19', 'a18NlSw', 46, 'Daisey Swinyard', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bpowys1a', 'sBRgG5LH7i', 47, 'Brod Powys', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('clinnit1b', 'F6JEHRj51', 48, 'Candida Linnit', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mbutson1c', 'tISnkLh', 49, 'Minne Butson', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('shalliburton1d', 'XYUWYuJn', 50, 'Selina Halliburton', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('brosencrantz1e', '2nW5b2', 51, 'Burty Rosencrantz', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lshortland1f', 'ejkRiSgkbk', 52, 'Liane Shortland', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('hwyllcock1g', 'ad7xGVA', 53, 'Hastings Wyllcock', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('griden1h', '7EXQ55NJu', 54, 'Gena Riden', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mguyer1i', 'Jf0husGAxUK', 55, 'Matty Guyer', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('wmcduffie1j', 'LLZFaoj', 56, 'Wilfrid McDuffie', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('egoodding1k', 'OS2MbWoP76', 57, 'Elsie Goodding', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lpetrello1l', '7gL1jmS', 58, 'Lyn Petrello', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cusborn1m', 'vF2B3E4S', 59, 'Chev Usborn', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mearsman1n', 'sfrhRJFuvZv9', 60, 'Maximilianus Earsman', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bnibloe1o', '5MTQIOT', 61, 'Bekki Nibloe', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bdenty1p', '7VNo2TPpB', 62, 'Benedict Denty', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jcullingford1q', 'KM0e1s', 63, 'Joly Cullingford', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mzmitruk1r', 'GhxI4EqSwF', 64, 'Michaelina Zmitruk', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mpechan1s', 'gn6E8aeOhI6', 65, 'Mohandis Pechan', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cfiennes1t', '2cs7H8zz43mo', 66, 'Chrystal Fiennes', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gprendergast1u', 'FZeMWOhg', 67, 'Gerardo Prendergast', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('nmuge1v', 'dZ9fa0KVT02', 68, 'Neile Muge', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('khansill1w', 'l3sepVx', 69, 'Kathye Hansill', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lkinneally1x', 'zeCQGPA1xh9', 70, 'Loree Kinneally', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('btroucher1y', 'kBtgrhI', 71, 'Bernie Troucher', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jkiddey1z', 'o4POYIX30Vd', 72, 'Jaime Kiddey', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tgovern20', 'haj1qNkCu', 73, 'Tawnya Govern', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lbloxland21', 'IQxWh65mMaz', 74, 'Lyon Bloxland', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mkewzick22', '8Io9VBBKr', 75, 'Minnnie Kewzick', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('hjedraszek23', 'eNY1KkepKK', 76, 'Harli Jedraszek', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('amcquilkin24', 'oVFI0bM', 77, 'Alisha McQuilkin', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('caisthorpe25', 'PCzXhUTQq7e0', 78, 'Chloris Aisthorpe', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jnorrie26', '6qRkNLlPH', 79, 'Jobi Norrie', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cschoffler27', 'bAPuLpaNbzK0', 80, 'Corrina Schoffler', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('jlangmaid28', 'ahce3l', 81, 'Jessey Langmaid', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mmitroshinov29', 'fuvBM8RWdFkX', 82, 'Myles Mitroshinov', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cfishpond2a', 'X8UK7yWE', 83, 'Caldwell Fishpond', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ftwentyman2b', 'CckIpH', 84, 'Felice Twentyman', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rfrede2c', 'PE1wO849bo', 85, 'Reg Frede', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('msarton2d', '8ZcLjrxI7yHL', 86, 'Matthias Sarton', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jchapple2e', 'MKQNLFR', 87, 'Jacquelynn Chapple', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bmccunn2f', 'vsMd821J', 88, 'Bobbye McCunn', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('skubes2g', '8xk77lXeZC1', 89, 'Sandy Kubes', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ggodbold2h', 'k1SdFCs1Z4', 90, 'Gregor Godbold', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('criediger2i', 'DFRQd9pn', 91, 'Christel Riediger', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lclue2j', 'wrU5lp', 92, 'Lionello Clue', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mscarlon2k', 'HpUo1o9AUX', 93, 'Manda Scarlon', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tsidnell2l', 'IMciYcVI', 94, 'Thatch Sidnell', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('spashler2m', 'lkdEZ23cwkXk', 95, 'Scott Pashler', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sstrother2n', 'HH5nRJFhCl', 96, 'Sidonia Strother', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gkeoghane2o', 'FsObcHdr', 97, 'Gabrila Keoghane', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cismirnioglou2p', 'xBwsRjrG5N', 98, 'Consalve Ismirnioglou', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sfather2q', 'FdqeLxPeR', 99, 'Slade Father', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mwolstenholme2r', '9GXLChfDj8', 100, 'Mame Wolstenholme', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('fgingell2s', '28KZ9XNK', 101, 'Fancie Gingell', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mmacbean2t', 'yH5QbBccoe8', 102, 'Myrvyn MacBean', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gfantonetti2u', 'uH9IwS8eq9', 103, 'Guillemette Fantonetti', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gduffrie2w', 'jSFkboVkJ', 105, 'Genni Duffrie', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('hchavez2x', 'XoVimMtgTO', 106, 'Hayyim Chavez', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mcrallan2y', '4jM29K', 107, 'Marvin Crallan', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cleverson2z', 'lMrrP7vwWqo', 108, 'Coriss Leverson', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jnicklen30', '2wjC3uqKX3g', 109, 'Jordan Nicklen', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rbabb31', '6GUVDA6', 110, 'Roseanne Babb', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gpyke32', 'Bcjqpurx7MO', 111, 'Gerry Pyke', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('jphysick33', '4UM4xAgtp', 112, 'Jess Physick', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jfairbeard34', 'c8DyF1', 113, 'Joelie Fairbeard', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('hlantaph35', 'a1e81Isql', 114, 'Hillier Lantaph', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('fbuttle36', 'FGwolLCCbGE7', 115, 'Franny Buttle', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jeydel37', '4OyWY0oZ3tGo', 116, 'Jenda Eydel', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('kmckevin38', 'tyR1KUrNcK8', 117, 'Krystyna McKevin', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('no39', 'z3ir7MmO', 118, 'Nanon O'' Quirk', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dtowers3a', 'r75ZSSvAU6Cq', 119, 'Deedee Towers', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lchristal3b', 'zlfZOK', 120, 'Lanni Christal', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mpoletto3c', '1vtXK8Q', 121, 'Mina Poletto', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('kleander3d', 'Q7ons4M', 122, 'Kort Leander', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('wbottleson3e', 'Q66KG2Cc', 123, 'Wilt Bottleson', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kyuryatin3f', 'qh8XloBv', 124, 'Ky Yuryatin', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ranthon3g', 'OpRoiflKse', 125, 'Rich Anthon', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jpicheford3h', 'JEuXRN8LDmKS', 126, 'Jory Picheford', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gwestfield3i', 'ElrdoxG0', 127, 'Gweneth Westfield', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mloy3j', 'SobT8Whad8M', 128, 'Marita Loy', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('atarge3k', 'VTVnH00f2fd', 129, 'Alfred Targe', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ewhiteoak3l', 'eLwVlIuuHrb', 130, 'Emalia Whiteoak', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lgarbar3m', 'kR8Z4t', 131, 'Lexie Garbar', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('po3n', 'GZB3NS', 132, 'Pat O Sullivan', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('sgrieswood3o', 'bV7MviCoq', 133, 'Sallie Grieswood', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gsavage3p', 'DqN2fwXvZYP', 134, 'Gaylene Savage', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('aalanbrooke3q', 'lXCEtv1I', 135, 'Albertina Alanbrooke', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rmeasham3r', 'QGCzJS1h6ojY', 136, 'Rhetta Measham', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('aanslow3s', 'h013HFZr8DQ', 137, 'Alis Anslow', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cwaleworke3t', '0EDphfhP', 138, 'Cody Waleworke', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lrapi3u', 'fYakcdhWM', 139, 'Lin Rapi', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('acommucci3v', 'cVDiJnJnq6', 140, 'Aurthur Commucci', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('blosbie3w', 'OWPNZ64xB', 141, 'Blanche Losbie', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mida3x', 'GQTRuU7nLbW', 142, 'Marianna Ida', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('glamswood3y', 'VI3JGyvW', 143, 'Gunner Lamswood', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('agavriel3z', '6xto9CydA', 144, 'Antonino Gavriel', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('acossum40', 'gpLsYso1', 145, 'Alethea Cossum', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cmactrustie41', 'PsYrh6BuNu', 146, 'Chandal MacTrustie', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jaleshkov42', 'Tx8tl7ORGK', 147, 'Jasen Aleshkov', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cnevison43', 'hmt7Vz9g8Riz', 148, 'Cari Nevison', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gmorbey44', 'cdYlv2Z7', 149, 'Georgianne Morbey', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cbrabon45', 'LPmFuOYAl', 150, 'Cointon Brabon', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ufowler46', 'BWM2dvr', 151, 'Urson Fowler', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jpartington47', 'u5GViet4xC', 152, 'Javier Partington', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gcorre48', 'vyqdZSsVwqO', 153, 'Guillermo Corre', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('wlaurenty49', 'pEDyITxDq', 154, 'Winfield Laurenty', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ggalliver4a', 'gIjwfywElZ8H', 155, 'Gaye Galliver', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('hbalharry4b', 'rmBBgv', 156, 'Humfrey Balharry', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bmedcraft4c', 'BVTUXn', 157, 'Brynna Medcraft', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sspencer4d', 'CA2d0UDopRU', 158, 'Shelton Spencer', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ohudel4e', '1fhqRpD8U6hR', 159, 'Obidiah Hudel', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('pkleingrub4f', 'YKTUdibo894', 160, 'Pacorro Kleingrub', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('heicke4g', 'VnEA25Ovh', 161, 'Hewie Eicke', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('dmackean4h', 'Yp2efzSJG0l', 162, 'Darcee MacKean', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('svauls4i', '1D6K80I6uL8l', 163, 'Sandy Vauls', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('amaccafferky4j', 'FaQrcmxP', 164, 'Andre MacCafferky', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('pbrumfitt4k', 's6zhCY6O', 165, 'Pete Brumfitt', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('aphilipp4l', 'tBgHq4', 166, 'Arie Philipp', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('chaylor4m', 'tUUngdTfA4', 167, 'Cale Haylor', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rgoodliffe4n', 'axyphIVf0FhU', 168, 'Ray Goodliffe', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('wjeaycock4o', 'IRgWwj9nPbO', 169, 'Willa Jeaycock', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ccurbishley4p', 'vyJivcS', 170, 'Cobby Curbishley', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('testoile4q', 'T0gNqoAnKIrO', 171, 'Tiena Estoile', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('channis4r', 'u75eEVx', 172, 'Cameron Hannis', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('emauditt4s', 'sKHcixdP', 173, 'Errol Mauditt', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mchipps4t', 'wMkpZ4', 174, 'Morten Chipps', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('nklemz4u', 'v6GZiv', 175, 'Nissie Klemz', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ggladtbach4v', 'ectC1GunN9wC', 176, 'Giffard Gladtbach', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('wmacmickan4w', 'pz5goGKRwAx', 177, 'Wilmar MacMickan', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('vforseith4x', 'aroqUjk8oXG', 178, 'Veronica Forseith', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('zingleson4y', 'bdM30X2', 179, 'Zebulon Ingleson', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('emessam50', 'dFNjly8wDZjP', 181, 'Elmer Messam', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('vohoolahan51', 'oSTQdvO4be', 182, 'Vonnie O''Hoolahan', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('kwyvill52', 'rfWZVpcW4Bk4', 183, 'Kirsten Wyvill', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mjoe53', 'hv2c4fli', 184, 'Miller Joe', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('wburroughes54', 'gpAITDyBFP7', 185, 'Willy Burroughes', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bfyers55', 'hhqxxGyFF', 186, 'Brunhilde Fyers', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('csimoens56', 'l0jPgCb', 187, 'Currie Simoens', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('emarien57', 'XZh57l', 188, 'Etheline Marien', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tdreelan58', 'PQcUwzRTRp8', 189, 'Teresita Dreelan', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('fmutimer59', 'gyCQebANMyf', 190, 'Frannie Mutimer', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lhurley5a', 'bmyOIydxEB', 191, 'Lauri Hurley', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tditty5b', 'Q6jxnKcGu0U', 192, 'Tracee Ditty', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('hjiruca5c', 'djp8VTtCCgQ4', 193, 'Hillel Jiruca', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cmollnar5d', 'YlFE8ZC', 194, 'Clemence Mollnar', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jabelwhite5e', '3a7qp13ovM', 195, 'Jarret Abelwhite', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mandreasson5f', 'UIXp4IM', 196, 'Marius Andreasson', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tdiboll5g', 'FuzW2b2', 197, 'Teresina Diboll', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('sbossons5h', 'jhvvrqjyLA', 198, 'Sanford Bossons', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('fbroome5i', 'Asysoemg4Kc', 199, 'Farris Broome', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('aprangnell5j', 'CspM7btXtI', 200, 'Aubert Prangnell', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jcometti5k', 'mKjpyYmm', 201, 'Jobey Cometti', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sgymblett5l', 'YVhz9UeSdQ', 202, 'Sharyl Gymblett', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gvest5m', 'yTMekdi', 203, 'Galen Vest', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('amoff5n', 'okl61c', 204, 'Ammamaria Moff', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cjagg5o', 'vNe8iL6zfX', 205, 'Carmela Jagg', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('malsop5p', 'FP3kFQR6C', 206, 'Marlow Alsop', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ecaress5q', 'FdoFAaQ', 207, 'Emilie Caress', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tpoter5r', 'zu4sjt', 208, 'Theresina Poter', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('sgrimmett5s', 'mDvD0sUZDb', 209, 'Shem Grimmett', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ejacmar5t', 'g3CL0YnH9', 210, 'Erroll Jacmar', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('acanedo5u', 'gCOh9GB4awfO', 211, 'Alvis Canedo', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mpeltz5v', 'JpcF77ASzu5', 212, 'Melinda Peltz', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jburet5w', 'Gq0m20', 213, 'Janaye Buret', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('oongin5x', 'ojHFIsHdfa', 214, 'Olga Ongin', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sguye5y', 'G5uSZ8', 215, 'Sheelah Guye', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bhoneyghan5z', 'UOEX64gSVRN', 216, 'Beck Honeyghan', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jximenez60', 'N6Dooh', 217, 'Jarib Ximenez', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('pswane61', 'OdkOVN72KF', 218, 'Penelope Swane', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('yoertzen62', 'fGSRVIU', 219, 'Yorker Oertzen', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('knielson63', 'eDY2ILF', 220, 'Krissie Nielson', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('agorbell64', 'lEZtffA', 221, 'Audre Gorbell', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cwinder65', 'YGeuFJo', 222, 'Chery Winder', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cenevold66', 'aLdfDhay', 223, 'Chadwick Enevold', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mfayter67', 'mK7grL1y4', 224, 'Maggie Fayter', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ahartas68', '9JAgjLKgqqvp', 225, 'Almeta Hartas', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dmclorinan69', 'Ibkf73mes', 226, 'Deerdre McLorinan', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mantunez6a', 'Cd1r3KcR1Zj4', 227, 'Maurise Antunez', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('eloades6b', 'iq9kFuLIt3UO', 228, 'Enriqueta Loades', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sditchett6c', 'g26Lau2', 229, 'Stanislaw Ditchett', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jtoulson6d', 'zdEonGm', 230, 'Jermaine Toulson', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('kgosselin6e', 'jDRF9JL', 231, 'Knox Gosselin', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('nbaythrop6f', '8CuLZeQ', 232, 'Natka Baythrop', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gaucutt6g', '5JncH9', 233, 'Guinna Aucutt', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jallpress6h', 'JQAg336kC', 234, 'Jed Allpress', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jtrett6i', '7iev9Pv2ii', 235, 'Jesus Trett', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ckeenlyside6j', 'fZSLAGG6CKE', 236, 'Cassi Keenlyside', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('hkryska6k', 'vgwD9l34f', 237, 'Hedy Kryska', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('nwalsh6l', 'uvmTL5', 238, 'Nata Walsh', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ayielding6m', 'G5BvDM', 239, 'Angelita Yielding', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('abackson6n', 'hTf44huX', 240, 'Angelle Backson', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rnevison6o', 'ibp8m8LHVl', 241, 'Rogerio Nevison', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('hbetancourt6p', 'UPjzjwujYg', 242, 'Honor Betancourt', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cgoning6q', 'qsVpfGZCxC', 243, 'Carley Goning', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('clockyer6r', '4oasRXR', 244, 'Cherish Lockyer', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cdohrmann6s', 'iQHl6ZON', 245, 'Clotilda Dohrmann', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('tions6t', 'wwVpXpCMLhG', 246, 'Tove Ions', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('dtregenza6u', 'q5GDbwd', 247, 'Deana Tregenza', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('hbrearley6v', '3IirSD2p', 248, 'Hadlee Brearley', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sadrianello6w', 'I1dxtTWAMfx', 249, 'Sawyer Adrianello', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('kwilmut6x', 'YuzdPkA', 250, 'Kain Wilmut', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('zwhiteson6y', 'XQx0eCdk', 251, 'Zaccaria Whiteson', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('hrentoll6z', 'uwvQyf', 252, 'Heddi Rentoll', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('pdoig70', 'eNfcvmTBbYVs', 253, 'Philippine Doig', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mburnie71', 'g4zS0w63H5od', 254, 'Misha Burnie', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cfoyston72', 'FcXu5Ttu', 255, 'Casey Foyston', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('agliddon73', 'VMO6BdaC', 256, 'Adelina Gliddon', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ygonsalvo74', 'H27QK4SUO2Cn', 257, 'Yank Gonsalvo', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cokenden75', 'VgemyD', 258, 'Clarance Okenden', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('fmagrane76', '3TDgwJ3BPLpS', 259, 'Friedrich Magrane', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lugolini77', 'BykCCcDzr', 260, 'Lannie Ugolini', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('avedeniktov78', 'bCfCgPtoY8LB', 261, 'Alwin Vedeniktov', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('dantic79', 'egtxnIaWExI', 262, 'Desmond Antic', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('pyve7a', 'nc7wvHiC', 263, 'Panchito Yve', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ponele7b', '5Am2tDo', 264, 'Peria Onele', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cminto7c', '5HxOJNZrO', 265, 'Cheston Minto', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('odanbi7d', 'QPYjyEC7M2g', 266, 'Orson Danbi', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cshobbrook7e', 'PFF00dRhGKV4', 267, 'Candis Shobbrook', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rmagrane7f', '6zfi8eH5io6m', 268, 'Risa Magrane', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rdemann7g', 'mzp2oGeMt6K', 269, 'Rubin Demann', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mbartosch7h', '8IbiPmGzKi4', 270, 'Marnia Bartosch', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('sbroadbridge7i', '7ONVKtz5lF8', 271, 'Stu Broadbridge', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mcornell7j', '6Fiuo8VhDIp', 272, 'Meredithe Cornell', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gbaribal7k', 'nG3mh7uOlE', 273, 'Glenda Baribal', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('fmathiassen7l', 's4C6ZwpGzX', 274, 'Faustina Mathiassen', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('khaken7m', 'vmJlsbCQDg', 275, 'Kaiser Haken', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('abaile7n', 'IKW84XE', 276, 'Andromache Baile', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cohartnett7o', 'zBuKVMa', 277, 'Claudia O''Hartnett', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('scaile7p', '0nLuMKYZAXB', 278, 'Scarface Caile', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dcollinette7q', 'jWW1R5tRn831', 279, 'Darcy Collinette', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rfoakes7r', 'HHDVdw8E', 280, 'Ring Foakes', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tnaton7s', 'vp4fYuX', 281, 'Tiffie Naton', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sleonards7t', 'nE4ZcvGT', 282, 'Sigfrid Leonards', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('gboullin7u', 'wEhlt3', 283, 'Georgena Boullin', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rclarycott7v', 'no6QTYcE', 284, 'Rollin Clarycott', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('kwickey7w', 'DeSgXrV', 285, 'Ki Wickey', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('tdupoy7x', 'MMtN2gCZ', 286, 'Tabbitha Dupoy', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mblackwood7y', 'W54KLEtta9Ps', 287, 'Matilde Blackwood', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sdancy7z', 'uL2OrIeCe', 288, 'Sallie Dancy', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('gdumingos80', 'kNu9cye', 289, 'Gerladina Dumingos', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mblenkinship81', 'usvMhiR', 290, 'Miriam Blenkinship', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('twenham82', 'HZ5wETDCDH', 291, 'Tobie Wenham', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('affoulkes83', 'QYMnZaRy', 292, 'Alaine Ffoulkes', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dputt84', 'NCXnT6u5m5yY', 293, 'Davide Putt', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('scarette86', 'PXrJdHn44WR', 295, 'Siegfried Carette', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('leede87', 'asrXL3kABD', 296, 'Laney Eede', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sdimmne88', '3VqwJnLCdM', 297, 'Shalne Dimmne', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ddenington89', 'XClndbL5r679', 298, 'Dolph Denington', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tchristauffour8a', 'rcS0qlRA7m', 299, 'Tally Christauffour', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('peverall8b', 'sSvmDlPKjmA', 300, 'Purcell Everall', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('do8c', 'QS2KaNCcvUF', 301, 'Desmund O'' Lone', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('sbeldam8d', 'fjc3n2Vn5', 302, 'Shannah Beldam', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('othorpe8e', 'R7vzgxcCatx3', 303, 'Otha Thorpe', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ecleen8f', 'UwwFpaaFgbZ', 304, 'Ella Cleen', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lyockney8g', 'XntKbn2Ltt', 305, 'Langsdon Yockney', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lelecum8h', 'OI5IIKCDxQXf', 306, 'Leigh Elecum', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gcastellucci8i', '6S3c7nyQns', 307, 'Gib Castellucci', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('amackaig8j', 'qD8o5vkt8ML9', 308, 'Andromache MacKaig', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ldartnell8k', 'CygtDgxkG', 309, 'Linus Dartnell', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('pnation8l', 'EjqvSH', 310, 'Patsy Nation', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mgilkison8m', 'yIENjBAGueW8', 311, 'Mia Gilkison', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mlavies8n', 'cGBiE3', 312, 'Margalo Lavies', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gcampsall8o', 'IGolQDNxX', 313, 'Germayne Campsall', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('randover8p', 'qsGTYryapT', 314, 'Roxana Andover', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('shamill8q', 'KPY1ORk', 315, 'Siusan Hamill', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('tstaker8r', 'okt0wU', 316, 'Talyah Staker', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bbyrth8s', 'Bl1He0da5U', 317, 'Bettina Byrth', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gsurman8t', '2qEEXAope2W', 318, 'Grove Surman', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ngodfree8u', 'e6FF2uNtSPV', 319, 'Nadeen Godfree', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bforsdicke8v', 'r3XjGdOlcOrK', 320, 'Brinna Forsdicke', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('slumsdall8w', 'Pwmm9h', 321, 'Sabina Lumsdall', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sworden8x', 'Yjj6V9W', 322, 'Stavros Worden', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bgarden8y', '0meLRwaOtZ', 323, 'Bartholomew Garden', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ko8z', '5cEPiQZ', 324, 'Kassandra O'' Gara', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tglyne90', '3d0p2WFHAsn', 325, 'Terri Glyne', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cfoxcroft91', 'SVRyhAsbEOU', 326, 'Constancy Foxcroft', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ggarfitt92', 'yyF89Imi', 327, 'Gerick Garfitt', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tglidden93', 'gnEWDwMC', 328, 'Tamma Glidden', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('erowlands94', 'XsBl8U', 329, 'Ely Rowlands', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rbriars95', 'Uhv7i9I', 330, 'Ronalda Briars', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('oskipton96', 'Ij6fW3', 331, 'Olive Skipton', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('atrent97', 'Cdm1JuJ', 332, 'Austine Trent', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('imartinez98', 'odBpujcH', 333, 'Ichabod Martinez', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bbiasi99', 'dacbSNK', 334, 'Berti Biasi', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('chobben9a', 'JeMMZ2HNXZ', 335, 'Culver Hobben', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jbastone9b', 'sathhyT', 336, 'Jarret Bastone', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rcummine9c', 'ZwvCfP2', 337, 'Regan Cummine', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cantat9d', 'Dl61Rz', 338, 'Carlotta Antat', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ljammet9e', 'AofnSZC', 339, 'Lorin Jammet', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bkarlicek9f', '2Prniqs', 340, 'Belva Karlicek', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jbrookfield9g', 'TFd1Uure1iu', 341, 'Jeth Brookfield', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cmacourek9h', '0k2Zjwtv3MFd', 342, 'Cynthy Macourek', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('disoldi9i', 'RwlcQ7', 343, 'Deonne Isoldi', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ehatchard9j', 'Ed3zVMrCF8', 344, 'Edan Hatchard', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('vgreen9k', 'xzci12KZF7', 345, 'Valentino Green', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('dstandley9l', 'kLf49B1', 346, 'Deerdre Standley', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sheckle9m', '66cph51xa', 347, 'Shermy Heckle', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jbridgett9n', 'tawGsMq13Y20', 348, 'Jordan Bridgett', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('akeerl9o', 'X2LbTGJL1m', 349, 'Allie Keerl', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cjzak9p', 'YRLSGWI', 350, 'Ches Jzak', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('aaizikovitz9q', 'qAMwYj', 351, 'Amberly Aizikovitz', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bcruickshank9r', 'Z28jvdVlZjdJ', 352, 'Belle Cruickshank', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sswate9s', 'PZXWOGCx3', 353, 'Stephenie Swate', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('hchat9t', 'MWCnMiowP1', 354, 'Holmes Chat', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bhorlick9u', 'eYbbDp23VA', 355, 'Bax Horlick', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('fsirman9v', 'YZZXXI', 356, 'Frederic Sirman', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lpennyman9w', '3oQxoaDz3', 357, 'Lea Pennyman', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lbrisbane9x', 'qRlfODtA5y0n', 358, 'Linette Brisbane', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('arake9y', 'DpgynAD6Xw2', 359, 'Arnaldo Rake', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('djambrozek9z', '7dDq3O', 360, 'Donnajean Jambrozek', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('tsodaa0', 'LgT8bVl3Hip', 361, 'Truda Soda', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mblytha1', 'wB7vNWVUCp5H', 362, 'Milty Blyth', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lcunaha2', 'aRKfkWj', 363, 'Lee Cunah', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lbevisa3', 'rIgIvOWJfz', 364, 'Luci Bevis', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('asambrooka4', 'pguEmvYc1xj', 365, 'Artemas Sambrook', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('amckearnena5', 'jq2ZuzyW', 366, 'Adoree McKearnen', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ggoldstona6', 'Hi2GO8yump', 367, 'Gabi Goldston', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lsmoutena7', 'x5vXrLXjuMLm', 368, 'Lin Smouten', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ccriellya8', '9LcObygOZh', 369, 'Carolynn Crielly', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bgladmana9', 'v7a9Gqfeo9', 370, 'Bernard Gladman', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('talamaa', '0DkejT', 371, 'Tucky Alam', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lpannerab', 'spoXnyuz', 372, 'Leila Panner', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jchildrenac', 'sPOx96Xg3efq', 373, 'Julee Children', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tgowenad', 'AS0gVNvc', 374, 'Ty Gowen', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ecockramae', '9894edQJ', 375, 'Edi Cockram', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dgethingsaf', 'a7AerfL', 376, 'Darell Gethings', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gbagnalag', 'Rie9e1a2OszD', 377, 'Glynnis Bagnal', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('squigah', 'oTiRxx8b', 378, 'Sylas Quig', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dtumasianai', '7bqu6AE', 379, 'Diana Tumasian', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('acluseaj', 'Wh3ERkA85PDW', 380, 'Alie Cluse', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bguppeyak', '1ghq65aU', 381, 'Belva Guppey', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('grarityal', 'XEXV3Hyv', 382, 'Gael Rarity', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mdeeream', 'm0bTuj', 383, 'Marcel Deere', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('brentoulan', 'umZHSPPOz', 384, 'Britt Rentoul', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rdominecao', 'Q90nt8qseR', 385, 'Rupert Dominec', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('teggertonap', 'myXcTj5f', 386, 'Theodore Eggerton', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mcoucheaq', '1HTokm', 387, 'Melba Couche', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('nwildsar', 'oAk3e5qt', 388, 'Nananne Wilds', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('kaspdenas', 'eL2rEcR', 389, 'Kristofor Aspden', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gkretschmerat', 'bIdKLwAuCM8', 390, 'Glyn Kretschmer', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('daartsenau', 'vtJeChBB6bR', 391, 'Dolph Aartsen', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('sgilliattav', 'o7NckPGNr', 392, 'Sylvia Gilliatt', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cmartyntsevaw', 'vTRZVhKbny', 393, 'Currey Martyntsev', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rtoffaloniax', 'JGIvvH5M', 394, 'Rubina Toffaloni', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('alubyay', 'oWySuZTzw', 395, 'Aprilette Luby', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kshovelaz', '5bQUCc', 396, 'Kata Shovel', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mmarushakb0', 'MjybHS', 397, 'Masha Marushak', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bdaskiewiczb1', 'nWrIY1lp2p', 398, 'Brooks Daskiewicz', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bandrieub2', 'Mowasjb0F6', 399, 'Brooke Andrieu', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('asummerleeb3', 'GqgMQMOuu9F', 400, 'Abrahan Summerlee', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('aloisib4', 'lEelv7S', 401, 'Alice Loisi', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('acurcherb5', 'PFki0h', 402, 'Alfreda Curcher', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('khabbershonb6', '2UVrRo', 403, 'Kimbra Habbershon', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('odebowb7', 'LoSdrrjgd', 404, 'Olag Debow', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rjothamb8', 'hyFM6hAJwIFI', 405, 'Renee Jotham', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ekobierzyckib9', 'I0oyXjcT', 406, 'Ediva Kobierzycki', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mhalfordba', 'W644hVuowD', 407, 'Morganne Halford', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('komoylanebb', 'e6E4kzEu99', 408, 'Kathi O''Moylane', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mlyddybc', 'uPfKStakvDR', 409, 'Melisse Lyddy', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bcollierbd', 'VD4aRinw4t1n', 410, 'Bartholomeus Collier', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ajeannardbe', 'y3JM2lFsfa0h', 411, 'Avril Jeannard', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('hdahlerbf', '7uAB2D', 412, 'Hilton Dahler', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('gmelmothbg', '1K45Wo', 413, 'Genni Melmoth', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('pfordycebh', '20umIH', 414, 'Pierce Fordyce', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cyettsbi', 'MPefOb', 415, 'Crosby Yetts', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cdonovanbj', 'ccT1ffPTYpR3', 416, 'Chic Donovan', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('kdawdrybk', 'ND17NNhdz', 417, 'Kelcie Dawdry', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('dgemnettbl', 'DexfG5vqIvo', 418, 'Deborah Gemnett', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('taizlewoodbm', 'KykrQDSjl4', 419, 'Tessa Aizlewood', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rgarnarbn', 'MTK2Q61oaVTW', 420, 'Raffarty Garnar', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('awetherheadbo', '5Wj2rxZ', 421, 'Adler Wetherhead', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sthebeaudbp', '48PDQ8hRjM', 422, 'Svend Thebeaud', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bemneybq', 'PW2APyUDc9', 423, 'Bliss Emney', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mfolibr', '0RfYY4IH653', 424, 'Marijo Foli', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kcornejobs', '4vj83u353', 425, 'Killy Cornejo', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cmcindrewbt', 'LRUcPpq0ymj', 426, 'Christy McIndrew', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rniccollsbu', '2riCVgfwFNM', 427, 'Raine Niccolls', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ayepiskopovbv', '1pMt0WXE5C', 428, 'Amanda Yepiskopov', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dtitteringtonbw', 'gMi1fnp', 429, 'Dode Titterington', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cpatleybx', 'BKkH2WP', 430, 'Cherin Patley', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gyuby', 'i72GCYkDgs', 431, 'Gael Yu', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('aguirardinbz', 'aad67kyeLNSK', 432, 'Alexander Guirardin', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cveillardc0', 'pjL31dG', 433, 'Crysta Veillard', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sdaymondc1', 'VmPUCxGcRrNV', 434, 'Sophia Daymond', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gslowlyc2', '5D17fl', 435, 'Gwenneth Slowly', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ptortoishellc3', '1I4UUuRhYksK', 436, 'Pamela Tortoishell', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('vshalec4', '8Coqu1o32D', 437, 'Vincenz Shale', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('csimeonc5', 'BNsZz1WokMiT', 438, 'Clare Simeon', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('dlockierc6', '8FjaphlzgP6E', 439, 'Darcey Lockier', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('xharlinc7', 'ZCKvUs3Jb4', 440, 'Xaviera Harlin', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tokellyc8', 'JsZuCvI0FQ', 441, 'Tracie O''Kelly', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('fdunckleyc9', 'aboE67w', 442, 'Ferdinand Dunckley', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sslowgroveca', 't13kokKSFO', 443, 'Sarajane Slowgrove', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lwhetnallcb', 'tYVKQiTEDtMC', 444, 'Leonanie Whetnall', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mdanielsencc', '04D664SUm', 445, 'Madeleine Danielsen', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ejonascd', 'qj9gdUH', 446, 'Eadie Jonas', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ulucience', 'YMAF0mXQ', 447, 'Udale Lucien', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bdumingoscf', 'Jwwzj3KtS', 448, 'Brion Dumingos', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('pprobyncg', 'PglLFNfQoOb', 449, 'Port Probyn', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('hronaldsonch', 'RlOy5Mboo', 450, 'Harli Ronaldson', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ssawlci', 'x0YPbRF', 451, 'Starla Sawl', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rmogglecj', 'MkAgR3PPTM5Z', 452, 'Ronny Moggle', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('acrallanck', 'dGsHRHBpBkBl', 453, 'Alexandr Crallan', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('fjirickcl', 'NNV0k4MiNJQ', 454, 'Flossy Jirick', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bmatthewscm', 'bq6uB2flSSC', 455, 'Berri Matthews', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sboddiscn', 'QzTFTA4PsBr', 456, 'Shel Boddis', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('aadamoco', '5SGUPVk', 457, 'Alexi Adamo', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lebrallcp', 'PUUYC7or6zVO', 458, 'Lilyan Ebrall', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('apiriecq', 'TSThmkcgl2y', 459, 'Alli Pirie', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gcattoncr', '1ZK6GE7ASjF', 460, 'Graig Catton', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cprestiecs', 'tISdosKI', 461, 'Caryl Prestie', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mmayoralct', 'coXHtfy', 462, 'Moe Mayoral', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cmarrowcu', 'tABvil', 463, 'Chev Marrow', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('dtoopecv', 'RduqsNEJP', 464, 'Danny Toope', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rdamantcw', 'O2Int9', 465, 'Raviv Damant', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ukernockecx', 'J1ihty', 466, 'Una Kernocke', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ltemplemancy', '8oR1Pf5', 467, 'Lev Templeman', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sgrigautcz', 'dnDPwmaPBjp', 468, 'Stephani Grigaut', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ashannahand0', 'EPw3s3', 469, 'Amalie Shannahan', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('aelwelld1', 'VYnMg3BW7K4P', 470, 'Alexander Elwell', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mbernatd2', 'EBlodiF51U', 471, 'Myrah Bernat', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('wglazierd3', 's3eppNT', 472, 'Wilden Glazier', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dpochind4', 'uPP4ugZVr3c', 473, 'Del Pochin', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('kleechmand5', 'y1L0THN4n', 474, 'Kimberlee Leechman', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bnajerad6', 'GB4DAkf5CM', 475, 'Bram Najera', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cnewbornd7', 'Ooaw9L', 476, 'Cordey Newborn', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bdonegand8', 'NFyOpArk37s0', 477, 'Bliss Donegan', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mdibnahd9', 'h24J2BJ', 478, 'Mathilde Dibnah', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('gsertinda', 'lgsQYt0DCz', 479, 'Gwendolen Sertin', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('xmehewdb', 'hVRNkarfx77', 480, 'Xenos Mehew', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('vsturdydc', 'cndVSCx1uj', 481, 'Vonnie Sturdy', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('gmacrorydd', 'XixXk0yosY9', 482, 'Gregoor MacRory', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tludgrovede', 'ndf2Lm9Y', 483, 'Traver Ludgrove', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lpettingalldf', 'cTIBi8RA', 484, 'Leisha Pettingall', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('oivakindg', 'B2BnpM', 485, 'Orelia Ivakin', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('fduleydh', 'RPTWjzskI', 486, 'Forbes Duley', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bjolleydi', 'mshk35', 487, 'Barry Jolley', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mhallowesdj', '9gw83CThwzKK', 488, 'Mead Hallowes', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sranniedk', 'zJNeQKE5Al0', 489, 'Skell Rannie', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ajenkendl', 'BGjfKLB6ACiS', 490, 'Aubrette Jenken', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('whatliffedm', '9jKdsK', 491, 'Whitman Hatliffe', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rcaslindn', 'DBTXh8rM', 492, 'Roxine Caslin', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ddeemingdo', 'rke5rQpZt1', 493, 'Delila Deeming', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('edealeydp', 'xP4HcM8F5', 494, 'Elfrida Dealey', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('csangodq', 'EOdVEmi40', 495, 'Cameron Sango', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cashtonhurstdr', 'u7mWABZOZ2E', 496, 'Curcio Ashtonhurst', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ldeds', 'x7WNrkCGPt', 497, 'Luciano De Laspee', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rrillattdt', 'QLLL9tExY', 498, 'Rosetta Rillatt', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mpilmoordu', '2Cy1pLSi', 499, 'Magdalen Pilmoor', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mfinckendv', 'bPSbkYxHIYMT', 500, 'Muriel Fincken', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rbartholomausdw', 'LAUMyv', 501, 'Ripley Bartholomaus', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cmcgerraghtydx', '2ocOIwlDqo0n', 502, 'Cammi McGerraghty', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('gbroomheaddy', '4QwPzj', 503, 'Gladys Broomhead', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('miviedz', 'NpXbU5ua', 504, 'Melita Ivie', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mmussettinie0', 'HgZFg5o4k', 505, 'Morie Mussettini', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('glegoode1', 'plq4CEYI5C', 506, 'Gerda Le-Good', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('kbaldacchie2', 'hAaJvjY', 507, 'Kareem Baldacchi', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gsainthille3', 'IgkrYX4J9HW', 508, 'Gherardo Sainthill', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ssouthcoate4', 'pX0vX41Oz', 509, 'Salome Southcoat', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rduxbarrye5', 'HzHgcj1', 510, 'Rudolfo Duxbarry', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mroadse6', 'Id4nIt5', 511, 'Maison Roads', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cpykee7', 'XjvbFE', 512, 'Cecelia Pyke', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tsnodinge8', 'AAglUc4S', 513, 'Trish Snoding', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cedworthiee9', 'wVsOcEmcJv', 514, 'Conchita Edworthie', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('dtrounceea', 'd8NiCF', 515, 'Devlen Trounce', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mcusickeb', 'L73jMC', 516, 'Mufinella Cusick', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lgiamoec', 'q6vce8UNq', 517, 'Lily Giamo', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sleisted', 'HJ4fTdd', 518, 'See Leist', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('denburyee', 'YlL55WC', 519, 'Devi Enbury', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rtigwellef', 'cdSFSW8M2', 520, 'Reid Tigwell', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jmappeg', 'uBSfliOL5', 521, 'Joli Mapp', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ymcilwraitheh', '9U6Z5zFTRo', 522, 'Yuma McIlwraith', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tmajorei', 'YTQCIOrkVLL', 523, 'Tiff Major', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jboalerej', 'AHWqzKs6x0B', 524, 'Jeane Boaler', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rbowllerek', 'wxBkI0JZ4V', 525, 'Rochell Bowller', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ctolerel', 'Ugyprd20SbU', 526, 'Conway Toler', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('fchueem', 'njHizgl9m8DA', 527, 'Frannie Chue', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mjupeen', '3hki8Yz', 528, 'Margette Jupe', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sblomfieldeo', 'iYisDbwzsa3', 529, 'Sullivan Blomfield', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gmernerep', 'o9bxjbhNraa', 530, 'Gaven Merner', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lcantrilleq', 'ebEOgz0J', 531, 'Lizette Cantrill', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('dpaulsener', '6WDOH0L', 532, 'Dov Paulsen', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('psloraes', '0jROjBFd1L', 533, 'Patsy Slora', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('npettifordet', 'MnZQeg3xoZf', 534, 'Norris Pettiford', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ppirnieeu', 'Cn4VsfUlR', 535, 'Paquito Pirnie', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('pmcallev', 'b5RvfplsKp', 536, 'Phillipp Mcall', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('wrowenaew', 'JncnnnA9', 537, 'Wally Rowena', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lmcquorkelex', 'X1nkBi', 538, 'Lesli McQuorkel', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kschrireney', 'TAPyB1w', 539, 'Kary Schriren', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rthirstez', 'lgkvOyU7xY', 540, 'Ruprecht Thirst', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cklammtf0', 'WXN1lVZy', 541, 'Cliff Klammt', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sspilisyf1', 'E3xRYHSW', 542, 'Steffie Spilisy', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('tollerf2', 'Q94umk93afp', 543, 'Talya Oller', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rchippingf3', 'vD4qF65uwo', 544, 'Rahel Chipping', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('acoalesf4', 'mY4TEBjlWL4', 545, 'Abby Coales', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('omccardlef5', 'W2axMoqLB', 546, 'Ollie McCardle', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rwithamf6', 'XiSTXu54', 547, 'Rafi Witham', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('pkirkupf7', 'nPJt4UD', 548, 'Piper Kirkup', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lveschif8', 'EyK1Z9fc', 549, 'Linus Veschi', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kpapaf9', 'lon7TXYRmV', 550, 'Katherina Papa', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dhoutbyfa', 'EicoCmR', 551, 'Delphinia Houtby', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bvancefb', '41h3tb9yzin', 552, 'Benn Vance', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lsemirazfc', 'tIWZq6', 553, 'Leon Semiraz', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sgrinstedfd', 'S7bMBlY2sfi', 554, 'Sharron Grinsted', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cthoroldfe', 'EtOWlbWx8', 555, 'Christyna Thorold', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mfarndaleff', 'ueZN5xm4AGZu', 556, 'Margie Farndale', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rwhyliefg', 'A4vSLIZhc', 557, 'Roxana Whylie', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('dhearlefh', 'QDNLhWBNE', 558, 'Desmund Hearle', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('hcordobesfi', 'IZQCoT9z', 559, 'Henryetta Cordobes', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('blightbodyfj', 'oITvpjEtDU', 560, 'Bentlee Lightbody', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('afromantfk', 'OeregwoNGB', 561, 'Adan Fromant', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('trakestrawfl', 'xzAdTNayzr', 562, 'Ted Rakestraw', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ilavingtonfm', 'wHMbTtL', 563, 'Izaak Lavington', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('osnookfn', 'e6jRuV', 564, 'Ody Snook', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('sleatonfo', 'RG9mRAfGcXL', 565, 'Stanley Leaton', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rronischfp', 'aIx3fT7zS00', 566, 'Rob Ronisch', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('amuddfq', 'ptHQT2sg', 567, 'Abramo Mudd', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rlowfr', 'fcZ1lAkQI', 568, 'Rhodia Low', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('noliveirafs', 'R02ZpUOZmU', 569, 'Nisse Oliveira', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('zschusterlft', '4oPbchIZDd', 570, 'Zelma Schusterl', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('prennelsfu', 'VF8V3F1MNm0', 571, 'Pavel Rennels', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('aworsfieldfv', 'Kd5EpK04a8', 572, 'Armstrong Worsfield', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('btockellfw', '0PoaJ9Sx', 573, 'Barris Tockell', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bklimmekfx', 'RT9Tlix', 574, 'Burnard Klimmek', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('usaltmarshfy', 'IGwruh2', 575, 'Udell Saltmarsh', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('kmurpheyfz', 'izZTdq', 576, 'Kory Murphey', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('dcorrisong0', '6bI4No', 577, 'Dina Corrison', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dghelardig1', 'waXvGL2TZTZ8', 578, 'Dex Ghelardi', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('adupreyg2', 'mNqi8AkbVwwy', 579, 'Adler Duprey', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('hindg3', 'Hhe6kbnXY', 580, 'Harlan Ind', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('dskullyg4', 'rzpDMQsKv', 581, 'Dolorita Skully', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gcaneg5', 'uscBfnafjzK', 582, 'Gearalt Cane', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('govanesiang6', 'wiy0r5UADl21', 583, 'Gillan Ovanesian', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('aloding7', 'IcmCRO2DPEq', 584, 'Anastasie Lodin', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bwickwarthg8', 'eILNV7lfy', 585, 'Barrett Wickwarth', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mbeddowsg9', 'n2Zb92', 586, 'Mendie Beddows', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bshealga', 'Fk6mzQl', 587, 'Bart Sheal', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bhasardgb', 'qyzswm', 588, 'Bradford Hasard', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cmangeongc', 'aMotU7hyPB', 589, 'Chet Mangeon', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('hdanagd', 'm02r8qSCzcD', 590, 'Hallie Dana', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('tbimsge', 'Y5vdgmmliF', 591, 'Tobey Bims', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rnadingf', 'aCkZ7Y', 592, 'Ruthie Nadin', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cmckimgg', 'p19pmgA', 593, 'Cris McKim', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rsibthorpgh', '9hFdEal', 594, 'Raquel Sibthorp', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('eobroganegi', 'cQ4hUSck', 595, 'Eduardo O''Brogane', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gdanzeygj', 'oIvSzjHZOxE', 596, 'Gian Danzey', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('jscotchbrookgk', 'cszFw3', 597, 'Jephthah Scotchbrook', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('dwittgl', '9FRUQF', 598, 'De witt Sanney', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mmclaffertygm', 'wjoqtWjiE9', 599, 'Marlo McLafferty', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rimortgn', 'J9u1HdFCQv30', 600, 'Rozele Imort', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('pfeltoego', '9aX9hXSmk7g3', 601, 'Patience Feltoe', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('frendlegp', '1EoZrVurS', 602, 'Finn Rendle', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('fcorkelgq', 'pJu8yS2SyjVY', 603, 'Fidel Corkel', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('acastillagr', 'xrT76TN', 604, 'Alexina Castilla', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dmontegs', 'DQnqZ4RCm', 605, 'Dalia Monte', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lleminggt', 'sKY6yl8PQ', 606, 'Laureen Leming', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mskillinggu', 'k1oE7G7r', 607, 'Madalyn Skilling', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lmcramseygv', 'QZUYuQ', 608, 'Leslie McRamsey', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('vstreetgw', 'aZP6w1a6F4', 609, 'Van Street', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('kpeschetgx', 'HYJtvjI', 610, 'Kendra Peschet', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mgunthorpgy', '72BKicU', 611, 'Mahalia Gunthorp', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('vkonertgz', 'fECtEHaKdLaf', 612, 'Vincent Konert', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('hdufallh0', 'oUeFKv9f', 613, 'Hobey Dufall', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('smellh1', '9AEAQSrcV', 614, 'Sylas Mell', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('jsarginth2', '7n6gWr4kGOj9', 615, 'Jenda Sargint', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('jcowleh3', 'EGYe35DpM5', 616, 'Josefa Cowle', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('kfostersmithh4', 'Hu6Luzd', 617, 'Kelsey Foster-Smith', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ncurnokh5', 'tJhj0x2Ld2aa', 618, 'Nichole Curnok', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gconlaundh6', 'oUwEpzdH', 619, 'Gideon Conlaund', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bbastinh7', 'NzMnJnJRe6', 620, 'Brett Bastin', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sdarrigoeh8', 'r89nJahWdd1', 621, 'Shayne Darrigoe', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('fboardmanh9', 'NGkpGiXN7Xn', 622, 'Freddie Boardman', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lwhyeha', 'Sa5JcM', 623, 'Lindi Whye', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('obreadmorehb', 'LNllughkS', 624, 'Omero Breadmore', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('sizzetthc', 'OiWyt2BN', 625, 'Sollie Izzett', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('delcehd', 'pArgagl3GS', 626, 'Dyanne Elce', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tmcvityhe', 'va3vPMhIvM', 627, 'Thalia McVity', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lperrotthf', 'vKe7Xg', 628, 'Lonee Perrott', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cashelfordhg', 'b0HeckWxU', 629, 'Carlita Ashelford', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mpochethh', '7L9lD8myzFV', 630, 'Merrel Pochet', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lalfhi', '7jnuQtLybe', 631, 'Linell Alf', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('slaxenhj', 'lATexuMRbEd', 632, 'Sigismund Laxen', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('kanelayhk', 'P2SY7w6', 633, 'Kinny Anelay', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('vjosefhl', 'PVFz7eTYVeeS', 634, 'Viv Josef', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dcahnhm', 'lYQLF2Sfma', 635, 'Donall Cahn', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('wnicklinsonhn', 'BS1OKX9Xu', 636, 'Winny Nicklinson', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('hshewonho', 'd994MSRaoOO0', 637, 'Heloise Shewon', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('dlongridgehp', 'TJPOzyA', 638, 'Deena Longridge', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('tpetchellhq', 'RFztlH7', 639, 'Tudor Petchell', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('uborithr', 'HGnYEuj8wm', 640, 'Ula Borit', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('lzanettohs', 'dEuSgqmaN9T', 641, 'Lyle Zanetto', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('dfussenht', 'QbVSaxymb3', 642, 'Dodi Fussen', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kgaytherhu', 'Sj9OFW', 643, 'Kacie Gayther', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('emicohv', 'RC4bZ8', 644, 'Emlyn Mico', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mwiddecombehw', 'tD9LJtuF', 645, 'Merline Widdecombe', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('nmidfordhx', '898c7cndE', 646, 'Nicki Midford', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rthackerayhy', 'UbpRbx', 647, 'Roxane Thackeray', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mduchesnehz', '9H20kJS', 648, 'Mandy Duchesne', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('pbuttrumi0', 'nSO8x3fl5t', 649, 'Park Buttrum', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('hbreami1', 'Zmz8oKhhseS', 650, 'Herminia Bream', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jquinanei2', 'vHmeZ6Q', 651, 'Jedediah Quinane', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ecluneyi3', 'oStQO7irInCG', 652, 'Elli Cluney', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('idei4', 'rJX8rzo1', 653, 'Inessa De Giorgi', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gchrismasi5', 'mf1zypUkDv', 654, 'Gayel Chrismas', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('edowsi6', 'gFFf3DMMbLT8', 655, 'Elnar Dows', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rhaineyi7', 'jIXvmUCt9', 656, 'Rosemarie Hainey`', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rchoulertoni8', 'PcTh9qjxZ4', 657, 'Rutger Choulerton', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kdecourcyi9', 'QeTC2wZX', 658, 'Kass Decourcy', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lhitteria', '1WPkyh2RGN', 659, 'Leela Hitter', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ecarlesiib', 'w4j4HQQ2z', 660, 'Eudora Carlesi', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tbullivantic', 'CAQ9ITL5', 661, 'Tamara Bullivant', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('nrunnallsid', 'AqmQDjnx5', 662, 'Nicolas Runnalls', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lcicchinelliie', 'EJ9k9AU61Ov', 663, 'Lian Cicchinelli', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kprophetif', 'dwA1D7zj2l', 664, 'Katinka Prophet', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ckuhleig', 'DKW6v4', 665, 'Camille Kuhle', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gparrattih', 'PBfyHYb5vUX', 666, 'Germain Parratt', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ablevinii', 'BYNbCHL84hlD', 667, 'Abbot Blevin', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ethirkettleij', 'Ps1Ayt0', 668, 'Elisha Thirkettle', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ltomeoik', '7OZrCM', 669, 'Lewiss Tomeo', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('smenureil', 'FS6fiEUMCY6', 670, 'Silvia Menure', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('featockim', 'LkQiew', 671, 'Faulkner Eatock', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jashpolein', '93MN7PkvP', 672, 'Joshua Ashpole', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('aarelesio', 'hsrncB0NZ3', 673, 'Ad Areles', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('aloganip', '0g22dJbqto', 674, 'Anatollo Logan', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('chargrovesiq', 'bAoHKhV', 675, 'Clevey Hargroves', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('nludwikiewiczir', 'PkjVsiSWkvr', 676, 'Niccolo Ludwikiewicz', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('vpresswellis', 'LFqoCqi306', 677, 'Vonnie Presswell', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('tdungeyit', 'qkfDSI8', 678, 'Ted Dungey', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gkilvingtoniu', '800ovh', 679, 'Grover Kilvington', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('hdorsayiv', 'L78BvrFQnox', 680, 'Hermione D''Orsay', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cnowakowskiiw', 'xzbTD9', 681, 'Carlotta Nowakowski', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('vnoriegaix', 'zHxssybVoty', 682, 'Vicki Noriega', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tnilesiy', 'qhik4f7GN', 683, 'Tabor Niles', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rcoomeriz', 'DHplLxy', 684, 'Rebekah Coomer', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ktoulsonj0', 'j6Xye1CCkXX', 685, 'Kore Toulson', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('fkenrickj1', 'p8ktXZWi', 686, 'Faber Kenrick', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('amcaughtryj2', 'EUGYK5ah5Sn', 687, 'Alvera McAughtry', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ctucsellj3', 'mUDCGNqQKkG9', 688, 'Cristal Tucsell', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lkienlj4', 'gZElPAfnXoc', 689, 'Lee Kienl', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mmasdenj5', 'FzWfeXK0', 690, 'Marianna Masden', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rkenealyj6', 'dY17wFz', 691, 'Reeba Kenealy', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('otheobaldj7', 'BzeEJAE', 692, 'Oralle Theobald', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('emcilwreathj8', 'w8ekmk', 693, 'Elden McIlwreath', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lpriumj9', 'QR0igFB1ja', 694, 'Lyndy Prium', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('nsousaja', 'CdkUm3KaQ', 695, 'Noam Sousa', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jgravesjb', 'FbpN9Y', 696, 'Jody Graves', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ccadejc', 'zKjybB3YqO3H', 697, 'Coriss Cade', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('tdalmanjd', '4B1Vtdxv', 698, 'Terrell Dalman', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('fhamnerje', 'YNIlxxQY6JAe', 699, 'Ferrell Hamner', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mnottinghamjf', 'HFTEsEA', 700, 'Mariana Nottingham', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('messamjg', 'oR48v6', 701, 'Mirabella Essam', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('zgoodbarrjh', 'uf1SDmG', 702, 'Zebadiah Goodbarr', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rsandifordji', 'fR63QkNPi6FX', 703, 'Renate Sandiford', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('slorrimerjj', '61iarm', 704, 'Skippy Lorrimer', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cconichiejk', 'Wx3GbN3fI', 705, 'Cristin Conichie', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('wdanilovitchjl', 'h1rZGlG', 706, 'Wolf Danilovitch', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('estarmorejm', 'zQt9Is', 707, 'Emery Starmore', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ikingswelljn', '53pUf9X6yW', 708, 'Ingunna Kingswell', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('agladebeckjo', 'OTnYgSIG3Y35', 709, 'Annamarie Gladebeck', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jwhaleyjp', '5w75FamrRa3y', 710, 'Jena Whaley', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('egarfathjq', '2Oz0fNbA6x', 711, 'Eward Garfath', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('aosbanjr', 'jtfep1', 712, 'Annette Osban', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ctommasuzzijs', 'EYeDjIoz', 713, 'Catrina Tommasuzzi', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mparysownajt', 'WzEM4WByVx', 714, 'Mikel Parysowna', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rcholominju', 'EKUfrt', 715, 'Reid Cholomin', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ihallumjv', 'm07OAJz', 716, 'Ive Hallum', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rmancejw', 'kPnaVC', 717, 'Rodge Mance', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('nhugeninjx', 'BTQVEJDq', 718, 'Noella Hugenin', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('wdedrickjy', 'D3QcKWDxhg5', 719, 'Wilone Dedrick', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('dvollethjz', 'CvK19g', 720, 'Dannie Volleth', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('itwentymank0', 'VqY9kJD6CQqo', 721, 'Isadora Twentyman', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('kkingdomk1', 'bsWH2QK', 722, 'Kipp Kingdom', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rodegaardk2', 'KkUZPy5lwM', 723, 'Reagan Odegaard', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('abreenk3', 'OhqTYNKHQ', 724, 'Antonella Breen', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ckenninghamk4', 'aKNFesSV', 725, 'Calypso Kenningham', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('swoodsfordk5', 'VHxxZ7YK', 726, 'Seumas Woodsford', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('arichiek6', 'pV4sGP4', 727, 'Ad Richie', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mschabenk7', 'ZR3Da7', 728, 'Maynord Schaben', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cbleymank8', 'bAzR5l', 729, 'Catherin Bleyman', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('trizzinik9', 'mNCGCZVXGU', 730, 'Tammy Rizzini', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sshoremanka', 'i4fIGN', 731, 'Sephira Shoreman', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('khadwenkb', 'PirPkvP3', 732, 'Keelia Hadwen', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tseareskc', 'La1SsypJh2R', 733, 'Tye Seares', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lamericikd', '9uVCxUq7', 734, 'Lizzie Americi', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('abengallke', '90ZWGHQ8eTE', 735, 'Antoni Bengall', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('tminettekf', 'VmdzYse17tm', 736, 'Torie Minette', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cdampierkg', 'bZoqKMms', 737, 'Carly Dampier', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lruscoekh', 'AHoqoY4Gm', 738, 'Lucais Ruscoe', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tscollandki', 'Ng2t45q0I', 739, 'Tania Scolland', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('dloudiankj', 'nRWtCtDF4', 740, 'Donall Loudian', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('dberthonkk', 'PngimYusZt', 741, 'Dione Berthon', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('vfilipczynskikl', 'FBWtBQHpvA', 742, 'Verene Filipczynski', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gtrenholmekm', 'dBcNxwLV6l', 743, 'Garrott Trenholme', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('amorelandkn', '1T784cBf', 744, 'Aile Moreland', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('tbowmakerko', '1bw9vc', 745, 'Tedra Bowmaker', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('santoninkp', 'lPXLgdJeed', 746, 'Sadye Antonin', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('dgerkenskq', 'q3oKrK2uEB', 747, 'Dex Gerkens', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('joreagankr', 'WyxeyJ', 748, 'Jonathan O''Reagan', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gbarradellks', 'HXaFBu', 749, 'Goran Barradell', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('kjanovskykt', 'D2U65O', 750, 'Keelia Janovsky', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cantonyku', 'wbhQddDSK77f', 751, 'Cecil Antony', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('standerkv', 'Sr5x2ffBsNR', 752, 'Stafani Tander', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tstrainkw', '41QQ1YWk', 753, 'Tine Strain', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('hcutforthkx', 'fmo8JchbBR', 754, 'Harcourt Cutforth', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('motridgeky', 'XMpbHj4w8z', 755, 'Mellicent Otridge', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jivashinnikovkz', 'zwSz8az0S5z', 756, 'John Ivashinnikov', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bmccloyl0', 'dRDaP3', 757, 'Bev McCloy', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sbarizeretl1', 'K8pNQpk', 758, 'Shae Barizeret', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cthorndalel2', '2lcgOJ', 759, 'Care Thorndale', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('wcattermolel3', 'pIfdC3c', 760, 'Wylie Cattermole', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('scoultl4', 'GJs7yiSEpWj', 761, 'Sherri Coult', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mdudbridgel5', 'Kfz4UMf', 762, 'Milli Dudbridge', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('qtilll6', 'kN1ddYrjWdv', 763, 'Quill Till', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('frylancel7', 'Jdt7rN0f5', 764, 'Fee Rylance', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('koldknowl8', 'A9HGfHW', 765, 'Kym Oldknow', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mgarlicl9', '0HH2CgWylc', 766, 'Marco Garlic', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('elindwasserla', 'cVTarcYn5b', 767, 'Eda Lindwasser', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jjaggarlb', 'Y8Lo6I', 768, 'Julio Jaggar', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bdafterlc', 'Km7amoU7', 769, 'Brita Dafter', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ctwinborneld', 'qZHBiyOLoU', 770, 'Colin Twinborne', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('okennionle', 'A8eVSO6a', 771, 'Olwen Kennion', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('uhuckinlf', 'xc1eEZDH', 772, 'Ulric Huckin', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cdantonilg', 'YX04hA', 773, 'Corissa D''Antoni', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('yyurocjkinlh', 'gVLVUI6e5', 774, 'Yovonnda Yurocjkin', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('hmalcherli', 'uDJvx7M', 775, 'Harriette Malcher', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mmonksfieldlj', 'wmTIxfD3a', 776, 'Maribel Monksfield', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('gmckuelk', 'l8pjs3FFZK', 777, 'Gill McKue', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tgilardonell', 'dQk8sXt', 778, 'Thibaud Gilardone', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('smantlm', '4dIHH5F', 779, 'Sisile Mant', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('imcgarrieln', 'DrIp3g', 780, 'Isabelita McGarrie', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('vgosnelllo', 'yPk61xIpy77', 781, 'Vanda Gosnell', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mtrevettlp', '9LuPUM', 782, 'Matthieu Trevett', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mdadgelq', 'xBdZPL3q', 783, 'Marleen Dadge', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('akunzelr', '0hbbldHLCBi', 784, 'Antonietta Kunze', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('csetfordls', 'iaBcLpwpdwPD', 785, 'Cordie Setford', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rroddanlt', 'VZQ8cUGaG', 786, 'Rodge Roddan', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('dgomerlu', '37EDRowAFYSU', 787, 'Diandra Gomer', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mcassinlv', 'ZYNuSboroa2', 788, 'Matthew Cassin', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ckocklw', 'LgQfBdNUTvaw', 789, 'Chad Kock', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('jyokleylx', 'HIuLjgqDgpE', 790, 'Joete Yokley', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('dstoddly', 'orpjzprJ', 791, 'Dagny Stodd', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mkochslz', 'NzTUc6z6', 792, 'Michaelina Kochs', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('hdaffornem0', 'xxfkhg7qd5', 793, 'Hortensia Dafforne', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mtorriem1', 'UqxFJyAe8fU', 794, 'Marcos Torrie', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('amallatrattm2', 'EwpajARqdjip', 795, 'Aksel Mallatratt', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sschwandermannm3', 'yMkaKJU4', 796, 'Seka Schwandermann', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('nreidem4', 'be2AJbT2jY', 797, 'Nicolle Reide', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('adonlonm5', 'P2FyD8', 798, 'Averyl Donlon', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ncovinom6', '9mX4OA7sj', 799, 'Natasha covino', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cvickersm7', 'yRZtKCwp', 800, 'Caspar Vickers', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('uledwardm8', 'KtCimBK', 801, 'Ulrich Ledward', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('pclemittm9', 'afDXL5TXP', 802, 'Petronella Clemitt', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('pohallihanema', 'zPejsv', 803, 'Peyter O''Hallihane', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mdashpermb', 'oUzOmqC', 804, 'Morly Dashper', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('pbyardmc', '9Io4tKREjl4', 805, 'Peggy Byard', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('asmithemanmd', 'i4GJzCiZ', 806, 'Allan Smitheman', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('dhyettme', 'iGvqgdSkZi', 807, 'Dynah Hyett', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ckeppinmf', 'XwHrhGp3', 808, 'Cherye Keppin', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mmcgheemg', 'JuRmlT5GN8', 809, 'Moore McGhee', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mbonnysonmh', 'nrLqEMD2o', 810, 'Malachi Bonnyson', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ajustmi', 'JCmGtI3', 811, 'Amaleta Just', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('uyerrallmj', 'zvBJQwzYc', 812, 'Urson Yerrall', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('doldnallmk', 'M6IG62ftu', 813, 'Donalt Oldnall', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('vwiltshawml', 'Qk20XYKXUQ', 814, 'Veronique Wiltshaw', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('sarboinmm', '4DMrcZs71naR', 815, 'Sayre Arboin', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('glemn', 'gGV2yM', 816, 'Guillema Le Pruvost', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('amacnessmo', 'bfzuwBpEPT', 817, 'Anson MacNess', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lcopseymp', 'j5rlzib2', 818, 'Liuka Copsey', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mjuschkemq', 'x038ZjreHEKS', 819, 'Marylou Juschke', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('semneymr', 'MH3u8JSEqG6e', 820, 'Sheff Emney', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('avellenderms', 'tPFVlx2i', 821, 'Alonso Vellender', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('gportmt', 'kiHHfhwr5', 822, 'Giffy Port', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('atullochmu', 'srU2W6g', 823, 'Archie Tulloch', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('snourymv', 'm7AGW0Vx1', 824, 'Sibyl Noury', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gvaskovmw', '2xgJKW8Jp', 825, 'Gleda Vaskov', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rescotmx', 'JHHq3NdZ', 826, 'Rollo Escot', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bbattermy', 'movwhG', 827, 'Brigitte Batter', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tenzleymz', 'Z9hSpDX', 828, 'Tilda enzley', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ggirlingn0', 'D8tgiWcOwmx', 829, 'Giacopo Girling', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bchaizen1', 'q7jCAQ', 830, 'Beilul Chaize', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jmackettn2', 'E7eBZcIM', 831, 'Jeno Mackett', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('hbeesn3', 'ogHdeuHNB', 832, 'Hayward Bees', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rcalcraftn4', 'TNrcxy', 833, 'Robby Calcraft', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ohearlen5', 'p5V9bz3jo', 834, 'Onfroi Hearle', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('betteridgen6', 'Qbg2Uh0Z2H', 835, 'Boigie Etteridge', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tboweringn7', 'Rb2PzCu', 836, 'Tootsie Bowering', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bcowdryn8', 'GD7lfd92EGOu', 837, 'Bruce Cowdry', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lwinfredn9', 'k5qQ4XRb', 838, 'Lucina Winfred', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cnevinsna', 'emNSGAZrJmz', 839, 'Conan Nevins', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('efraczaknb', 'qi8ghWS', 840, 'Eudora Fraczak', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('gantyshevnc', '8fsWYUtC', 841, 'Gabriellia Antyshev', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cmaryetnd', 'vAMMUZoFbWUi', 842, 'Carri Maryet', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('csuerone', 'vl4hYf', 843, 'Cirstoforo Suero', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mwilkisonnf', 'rHKclFMGXPPs', 844, 'Mallory Wilkison', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('haysikng', 'Cef5vS4JNUMZ', 845, 'Hendrik Aysik', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('apenricenh', 'JKSir32uK', 846, 'Avis Penrice', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kcharlotni', '9OB0IXJ', 847, 'Kevin Charlot', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sbriscamnj', 'zhrFnIeFDp', 848, 'Sib Briscam', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mhinzernk', 'FfjucOt', 849, 'Marian Hinzer', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('wmckeadynl', 'oR89WiQdP', 850, 'Winifield McKeady', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cgeraschnm', 'KlzFVEivx', 851, 'Carney Gerasch', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lpatersonnn', 'D6O5R0', 852, 'Linnea Paterson', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('vginieno', 'qBK0OdhQ', 853, 'Virginie Ginie', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ssteptonp', 'rTiVfTk', 854, 'Sashenka Stepto', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ematticcinq', 'IwTF69P', 855, 'Errol MattiCCI', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ahealeasnr', 'DlLXtq63N', 856, 'Ardyce Healeas', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bhuzzeyns', 'Iwt03ctG9d', 857, 'Brant Huzzey', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('nspieghtnt', '3qTRKi1f', 858, 'Nikolia Spieght', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('aanlaynu', 'YqxIrmSSlChz', 859, 'Armand Anlay', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bdjekovicnv', 'L0xyGJ', 860, 'Baxy Djekovic', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ddjokovicnw', 'uZDLfJ', 861, 'Doris Djokovic', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('adooneynx', 'IBB6tmI', 862, 'Avrom Dooney', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lduffilnz', 'Ls2JH8FuZ', 864, 'Liuka Duffil', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('gdanfortho0', 'ZjWBRZsWs1ed', 865, 'Giffie Danforth', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ecollyearo1', 'azpWMOk22koa', 866, 'Estrella Collyear', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cgrichukhanovo2', 'sQ4DQbE2v7', 867, 'Cathrine Grichukhanov', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jduigenano3', 'bJsY6i', 868, 'Jody Duigenan', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('nbarkero4', 'aPKBhqJ', 869, 'Nedi Barker', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('meastmondo5', 'uyxKJxSW0', 870, 'Marguerite Eastmond', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('iodreaino6', 'EhCDLMA', 871, 'Isa O''Dreain', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('plohoaro7', 'zxwHbwF17or', 872, 'Peg Lohoar', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('eantico8', 'i9n75Gfl', 873, 'Emmye Antic', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('wsilletto9', '37AN6pw', 874, 'Wenonah Sillett', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('aelizabethoa', '6Gzc2VUl5UY', 875, 'Antony Elizabeth', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('edicheob', 'nq7WZFrbQs', 876, 'Emilio Diche', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ubavridgeoc', 'MZNO5EJO1u', 877, 'Umberto Bavridge', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ecluelyod', 'IHD9PbcP', 878, 'Estele Cluely', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ckillingbeckoe', 'EzgAkZv6X', 879, 'Cammi Killingbeck', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('gschwierof', 'un66sAr', 880, 'Gillian Schwier', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('bharropog', '0XPzD562q', 881, 'Bernadene Harrop', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kitzikoh', 'bLjlB2AvqrN', 882, 'Kellina Itzik', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('fonolandoi', 'gL7LlLlN', 883, 'Fidelia O''Noland', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('olaphornoj', 'EJCOjgaV3', 884, 'Ofella Laphorn', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jjinkinsonok', 'HlbPe3hQU', 885, 'Jessi Jinkinson', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cvolkesol', 'wKpSNgtra', 886, 'Cordelie Volkes', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('hlameyom', 'E6MDHB6DzO6J', 887, 'Hildegarde Lamey', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('lpetrion', '2GQ2YKgwA2KJ', 888, 'Lulu Petri', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('hkilbourneoo', 'aUBquM1x1N', 889, 'Hildegarde Kilbourne', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mdimitrescuop', 'pdZoLfekzf', 890, 'Melloney Dimitrescu', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lmoodycliffeoq', 'bHWNDaq', 891, 'Laurie Moodycliffe', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mjancyor', 'lxHfVVxIT', 892, 'Marrissa Jancy', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('calvaradoos', 'sBi543yxxImC', 893, 'Case Alvarado', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rpetracchiot', 'jOrgnUQWTh', 894, 'Rossy Petracchi', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cmeechou', 'LCgi2Q', 895, 'Con Meech', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rmichelov', 'GJtBcclqFI', 896, 'Reggie Michel', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('dbaymanow', 'wbJcZxhntq1', 897, 'Dallis Bayman', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('zmasiox', 's9gwzX', 898, 'Zebulen Masi', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mvelarealoy', 'bQDlKZQe', 899, 'Meryl Velareal', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('jtaggertoz', 'LYHBjy', 900, 'Jourdain Taggert', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('asinnattp0', 'bwsxf5A3', 901, 'Ario Sinnatt', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cstormsp1', 'nILZTUu', 902, 'Celeste Storms', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('koulettp2', 'a3FgqbFDx', 903, 'Kristine Oulett', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('hnajafianp3', 'RsCBbaZ', 904, 'Harlin Najafian', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('kcocklingp4', 'OhEZFdYjues', 905, 'Kahlil Cockling', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mraittp5', 'r24GrIH', 906, 'Mord Raitt', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sburnhamsp6', 'g5SRfRyRv', 907, 'Sibel Burnhams', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mshevelinp7', 'kakeXtkc7', 908, 'Marrilee Shevelin', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('kthamep8', 'fNHr4u7DDQL', 909, 'Kimberly Thame', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('marnaldyp9', 'OnklqZ8gUmk', 910, 'Marya Arnaldy', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('adrancepa', 'sCk1Dj', 911, 'Anne Drance', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('etubblepb', '8WTwiA', 912, 'Eben Tubble', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('iskynerpc', 'N341RuBG2bR', 913, 'Ichabod Skyner', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('bselburnpd', 'cv3fl9qkXaaz', 914, 'Binny Selburn', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('cleitherpe', '1OSXLUzvTW', 915, 'Charissa Leither', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('igerholdpf', 'qNduFa', 916, 'Isac Gerhold', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ijeanonpg', 'ngpfy6SRg', 917, 'Inglebert Jeanon', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('pguilletonph', 'Ufa8fi7', 918, 'Phelia Guilleton', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('mdudnypi', 'N0dUapMKVQFM', 919, 'Myrta Dudny', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jofferpj', 'qe0MBlhx3je', 920, 'Jean Offer', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tnajerapk', '1slco8iVIJSs', 921, 'Trenton Najera', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mpotterypm', 'JXKJQHi', 923, 'Marthena Pottery', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('ebrettlepn', '1B5Qm2D', 924, 'Emile Brettle', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jtoulamainpo', 'WtrMqaRLckQ', 925, 'Jessalin Toulamain', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('awhitterpp', '75R73YKvTu6i', 926, 'Antin Whitter', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('apattissonpq', 'Fn6siPb', 927, 'Adrian Pattisson', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('epicktonpr', 'ZFlpqW11', 928, 'Eliot Pickton', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('kbiasiolips', '7MALRJRjc9q9', 929, 'Kipper Biasioli', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('nlinfootpt', 'z6r8pxo', 930, 'Nat Linfoot', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('hhaggerwoodpu', 'sgNudVeEd', 931, 'Hagen Haggerwood', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cjeacockpv', 'U43oLVKPSTQ', 932, 'Cherice Jeacock', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('ecoghlinpw', 'gVe15458', 933, 'Elset Coghlin', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('abeneditopx', 'he4t6DH9', 934, 'Adiana Benedito', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mcalderpy', 'W0QlmLmBXh', 935, 'Milicent Calder', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('asiebertpz', 'o30jW0ab0fU', 936, 'Albina Siebert', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('kwalterq0', 'Jbs2qZ', 937, 'Katti Walter', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('cglyneq1', 'VorZjP68', 938, 'Chlo Glyne', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('aduffellq2', 'ckbrtJ4', 939, 'Alysa Duffell', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sglantonq3', '9bs9PlVe', 940, 'Shandeigh Glanton', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jbuttingq4', 'jQbJGIK', 941, 'Jacqui Butting', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('hdalrympleq5', '0ydX5eRNhDbr', 942, 'Hamlin Dalrymple', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rlansberryq6', 'TyZny1Zp12', 943, 'Ray Lansberry', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('kelietq7', 'HQloYHVyW', 944, 'Katha Eliet', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lmuzziq8', 'EmhCfrLbJFd0', 945, 'Linea Muzzi', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('yreaperq9', 'WH0c10F', 946, 'Yolanthe Reaper', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jbaignardqa', 'eE60ucz', 947, 'Jarrid Baignard', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('fwedmoreqb', 'VF4AtR7EYOR6', 948, 'Fannie Wedmore.', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('hfairleighqc', 'BJPpRgW', 949, 'Hakeem Fairleigh', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rasletqd', 'RrGgr0ba', 950, 'Rodrique Aslet', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('mdowsettqe', 'UT7WWH', 951, 'Mirabella Dowsett', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tjasperqf', 'H6NMsTuFAQ', 952, 'Theodoric Jasper', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('wwebbeqg', 'T4ueMM1yUg', 953, 'Wang Webbe', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ioharaqh', '1UoEJJ6o', 954, 'Ingrid O''Hara', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bpiolaqi', 'g9gPlk7y3KB7', 955, 'Baily Piola', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rgiraudouxqj', 'BGlOtgTbfBRj', 956, 'Rafaelia Giraudoux', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tansettqk', 'TzvLPRMRvc', 957, 'Tori Ansett', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('rpennigarql', 'a8E9PNZ', 958, 'Rufe Pennigar', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bstutelyqm', '33pW6G8K', 959, 'Bonnee Stutely', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sdevasqn', 'GtGcqgDE', 960, 'Sorcha Devas', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('msharphurstqo', '2g2gMhyv', 961, 'Mord Sharphurst', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lvieyraqp', 'Z6m2pdXgZ1gh', 962, 'Laureen Vieyra', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('sdrewsqq', 'Vi8VhEYSJ', 963, 'Shermie Drews', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('rliddleqr', '8ktrMerm4s', 964, 'Reinald Liddle', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('pjackmanqs', 'HMiddfx80A', 965, 'Phelia Jackman', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('lalliotqt', '7PhEA4Gq', 966, 'Layney Alliot', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('pmccunnqu', 'lPpCmmmo', 967, 'Pauli McCunn', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('pstanneyqv', 'JysxdEP', 968, 'Pavla Stanney', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('daslieqw', 'jOxiVpYvc', 969, 'Dan Aslie', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('vkenealyqx', 'faN4Rry', 970, 'Valaria Kenealy', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('rbodemeaidqy', 'O4JyxpsYD', 971, 'Rochester Bodemeaid', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('gtorransqz', 'MYzFd9QMFnVt', 972, 'Granger Torrans', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('fmineror0', 'yoVRhvwzOy', 973, 'Faye Minero', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('sportamr1', 'LheJKKp', 974, 'Sallyanne Portam', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('hspittlesr2', 'JyROBX', 975, 'Haley Spittles', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('wshivlinr3', 'PFMXhWGJITH', 976, 'Westbrook Shivlin', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bgaitskellr4', 'dmMG0aCbxsL', 977, 'Bernarr Gaitskell', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jblazyr5', 'IRIAAqm', 978, 'Jobyna Blazy', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('ldeloozer6', 'KzoOB0pfT7', 979, 'Ladonna Delooze', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('gtuhyr7', 'U0ryDHk', 980, 'Giustina Tuhy', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('amchirrier8', 'KQHXyLzL', 981, 'Anthea M''Chirrie', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('psinclarr9', 'eAc8lNbHTVu', 982, 'Philbert Sinclar', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('jdomnickra', 'bu1339', 983, 'Jeremias Domnick', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('xquereerb', 'EzPv74z4', 984, 'Xylina Queree', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('nbroadyrc', 'fIx7mbEsI6', 985, 'Nadean Broady', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('fvalentinettird', 'JS5pFGDrDf', 986, 'Filmore Valentinetti', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('tbaptistare', 'tvZ4pRrN', 987, 'Ty Baptista', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('hculprf', 'ThdLC6Z', 988, 'Hyacinthie Culp', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('eredolfirg', 'DpFVn9qsTB', 989, 'Eadith Redolfi', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('elebbernrh', 'TUyI6vCR', 990, 'Elmira Lebbern', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('djessoppri', 'nLnLUCAE', 991, 'Darci Jessopp', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('tsiggersrj', 'vM48bilGsQO', 992, 'Torin Siggers', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('levittsrk', 'TuU1Qi', 993, 'Liana Evitts', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('czavatterorl', 'UPP8oLj', 994, 'Colleen Zavattero', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mfluxrm', 'xF2rTZ1J4f', 995, 'Maiga Flux', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mmattiaccirn', '3HXmC8NPty1', 996, 'Myriam Mattiacci', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('wcaldronro', 'WSgEn52', 997, 'Warden Caldron', 'S', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('tcoffeerp', 'V6PvQCu', 998, 'Tyson Coffee', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('mgristonrq', 'nqyM40A0eQZ2', 999, 'Mac Griston', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('jverduinrr', 'mtVXpLKopti', 1000, 'Jonathon Verduin', 'S', NULL, NULL, NULL, NULL, 2);
INSERT INTO usuario VALUES ('alippatt4z', 'BNaL1dXBc', 180, 'Annabell Lippatt', 'N', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('bbaystingny', 'MJjfwxNcfs', 863, 'Burch Baysting', 'N', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('cabramzon85', 'xBEFqqCEN', 294, 'Clementina Abramzon', 'N', NULL, NULL, NULL, NULL, 3);
INSERT INTO usuario VALUES ('callbrook0', '4h5yaK', 1, 'Carmela Allbrook', 'N', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('hespinosa', '%#$%#$', 1, 'Herlin Espinosa', 'S', NULL, NULL, NULL, NULL, 1);
INSERT INTO usuario VALUES ('acripin2v', 'xusQpsCbmd', 104, 'Alyse Cripin', 'N', NULL, NULL, NULL, NULL, 2);


--
-- TOC entry 2154 (class 2606 OID 35326)
-- Name: employee_audits employee_audits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employee_audits
    ADD CONSTRAINT employee_audits_pkey PRIMARY KEY (id);


--
-- TOC entry 2152 (class 2606 OID 35318)
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (id);


--
-- TOC entry 2129 (class 2606 OID 35130)
-- Name: cliente key1; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cliente
    ADD CONSTRAINT key1 PRIMARY KEY (clie_id);


--
-- TOC entry 2131 (class 2606 OID 35141)
-- Name: tipo_documento key2; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tipo_documento
    ADD CONSTRAINT key2 PRIMARY KEY (tdoc_id);


--
-- TOC entry 2134 (class 2606 OID 35150)
-- Name: cuenta key3; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cuenta
    ADD CONSTRAINT key3 PRIMARY KEY (cuen_id);


--
-- TOC entry 2138 (class 2606 OID 35163)
-- Name: cuenta_registrada key4; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cuenta_registrada
    ADD CONSTRAINT key4 PRIMARY KEY (cure_id);


--
-- TOC entry 2143 (class 2606 OID 35177)
-- Name: transaccion key5; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaccion
    ADD CONSTRAINT key5 PRIMARY KEY (tran_id);


--
-- TOC entry 2146 (class 2606 OID 35186)
-- Name: usuario key6; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT key6 PRIMARY KEY (usu_usuario);


--
-- TOC entry 2148 (class 2606 OID 35197)
-- Name: tipo_usuario key7; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tipo_usuario
    ADD CONSTRAINT key7 PRIMARY KEY (tius_id);


--
-- TOC entry 2150 (class 2606 OID 35208)
-- Name: tipo_transaccion key8; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY tipo_transaccion
    ADD CONSTRAINT key8 PRIMARY KEY (titr_id);


--
-- TOC entry 2156 (class 2606 OID 35376)
-- Name: huella key99; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY huella
    ADD CONSTRAINT key99 PRIMARY KEY (id);


--
-- TOC entry 2158 (class 2606 OID 35395)
-- Name: huella_tmp key999; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY huella_tmp
    ADD CONSTRAINT key999 PRIMARY KEY (id);


--
-- TOC entry 2127 (class 1259 OID 35128)
-- Name: ix_relationship1; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_relationship1 ON cliente USING btree (tdoc_id);


--
-- TOC entry 2132 (class 1259 OID 35148)
-- Name: ix_relationship2; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_relationship2 ON cuenta USING btree (clie_id);


--
-- TOC entry 2135 (class 1259 OID 35160)
-- Name: ix_relationship3; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_relationship3 ON cuenta_registrada USING btree (clie_id);


--
-- TOC entry 2136 (class 1259 OID 35161)
-- Name: ix_relationship4; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_relationship4 ON cuenta_registrada USING btree (cuen_id);


--
-- TOC entry 2139 (class 1259 OID 35173)
-- Name: ix_relationship5; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_relationship5 ON transaccion USING btree (cuen_id);


--
-- TOC entry 2144 (class 1259 OID 35184)
-- Name: ix_relationship6; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_relationship6 ON usuario USING btree (tius_id);


--
-- TOC entry 2140 (class 1259 OID 35174)
-- Name: ix_relationship7; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_relationship7 ON transaccion USING btree (usu_usuario);


--
-- TOC entry 2141 (class 1259 OID 35175)
-- Name: ix_relationship8; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_relationship8 ON transaccion USING btree (titr_id);


--
-- TOC entry 2167 (class 2620 OID 35328)
-- Name: employees last_name_changes; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER last_name_changes BEFORE UPDATE ON employees FOR EACH ROW EXECUTE PROCEDURE log_last_name_changes();


--
-- TOC entry 2160 (class 2606 OID 35214)
-- Name: cuenta fk_cliente_cuenta; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cuenta
    ADD CONSTRAINT fk_cliente_cuenta FOREIGN KEY (clie_id) REFERENCES cliente(clie_id);


--
-- TOC entry 2161 (class 2606 OID 35219)
-- Name: cuenta_registrada fk_cliente_cuenta_registrada; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cuenta_registrada
    ADD CONSTRAINT fk_cliente_cuenta_registrada FOREIGN KEY (clie_id) REFERENCES cliente(clie_id);


--
-- TOC entry 2162 (class 2606 OID 35224)
-- Name: cuenta_registrada fk_cuenta_cuenta_registrada; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cuenta_registrada
    ADD CONSTRAINT fk_cuenta_cuenta_registrada FOREIGN KEY (cuen_id) REFERENCES cuenta(cuen_id);


--
-- TOC entry 2163 (class 2606 OID 35229)
-- Name: transaccion fk_cuenta_transaccion; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaccion
    ADD CONSTRAINT fk_cuenta_transaccion FOREIGN KEY (cuen_id) REFERENCES cuenta(cuen_id);


--
-- TOC entry 2165 (class 2606 OID 35244)
-- Name: transaccion fk_tipo_transaccion_transaccion; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaccion
    ADD CONSTRAINT fk_tipo_transaccion_transaccion FOREIGN KEY (titr_id) REFERENCES tipo_transaccion(titr_id);


--
-- TOC entry 2166 (class 2606 OID 35234)
-- Name: usuario fk_tipo_usuario_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY usuario
    ADD CONSTRAINT fk_tipo_usuario_usuario FOREIGN KEY (tius_id) REFERENCES tipo_usuario(tius_id);


--
-- TOC entry 2159 (class 2606 OID 35209)
-- Name: cliente fk_tipodocumento_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cliente
    ADD CONSTRAINT fk_tipodocumento_cliente FOREIGN KEY (tdoc_id) REFERENCES tipo_documento(tdoc_id);


--
-- TOC entry 2164 (class 2606 OID 35239)
-- Name: transaccion fk_usuario_transaccion; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY transaccion
    ADD CONSTRAINT fk_usuario_transaccion FOREIGN KEY (usu_usuario) REFERENCES usuario(usu_usuario);


-- Completed on 2019-11-30 03:59:45

--
-- PostgreSQL database dump complete
--

