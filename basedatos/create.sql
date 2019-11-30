CREATE DATABASE bank
  WITH OWNER = postgres
       ENCODING = 'UTF8'
       TABLESPACE = pg_default;
	   


CREATE TABLE public.huella
(
  id bigserial NOT NULL,
  release character varying(151) NOT NULL,
  fecha character varying NOT NULL,
  tipo character varying NOT NULL,
  objecto character varying NOT NULL,
  codigo text,
  CONSTRAINT key99 PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.huella
  OWNER TO postgres;
  
  
-- Table: public.huella_tmp

-- DROP TABLE public.huella_tmp;

CREATE TABLE public.huella_tmp
(
  id bigserial NOT NULL,
  release character varying(151) NOT NULL,
  fecha character varying NOT NULL,
  tipo character varying NOT NULL,
  objecto character varying NOT NULL,
  codigo text,
  codigo2 text,
  CONSTRAINT key999 PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.huella_tmp
  OWNER TO postgres;
  
-- Function: public.fc_generarrelease(text, text)

-- DROP FUNCTION public.fc_generarrelease(text, text);

CREATE OR REPLACE FUNCTION public.fc_generarrelease(
    text,
    text)
  RETURNS void AS
$BODY$
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
			INSERT INTO huella VALUES(DEFAULT,D_nombre,D_date,Result.table_name,R_sha256);
		END LOOP;

		FOR Result2 IN 
			SELECT sequence_name FROM information_schema.sequences
		LOOP
			SELECT INTO R_sha256 fc_sha256sequence(Result2.sequence_name);
			INSERT INTO huella VALUES(DEFAULT,D_nombre,D_date,Result2.sequence_name,R_sha256);
		END LOOP;

		FOR Result3 IN 
			SELECT routines.routine_name
			FROM information_schema.routines
			LEFT JOIN information_schema.parameters ON routines.specific_name=parameters.specific_name
			WHERE routines.specific_schema='public' AND routines.routine_name ILIKE ('fc_%')
			ORDER BY routines.routine_name, parameters.ordinal_position
		LOOP
			SELECT INTO R_sha256 fc_sha256sequence(Result3.routine_name);
			INSERT INTO huella VALUES(DEFAULT,D_nombre,D_date,Result3.routine_name,R_sha256);
		END LOOP;
	END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.fc_generarrelease(text, text)
  OWNER TO postgres;

-- Function: public.fc_sha256function(text)

-- DROP FUNCTION public.fc_sha256function(text);

CREATE OR REPLACE FUNCTION public.fc_sha256function(text)
  RETURNS text AS
$BODY$
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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.fc_sha256function(text)
  OWNER TO postgres;

-- Function: public.fc_sha256sequence(text)

-- DROP FUNCTION public.fc_sha256sequence(text);

CREATE OR REPLACE FUNCTION public.fc_sha256sequence(text)
  RETURNS text AS
$BODY$
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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.fc_sha256sequence(text)
  OWNER TO postgres;


-- Function: public.fc_sha256table(text)

-- DROP FUNCTION public.fc_sha256table(text);

CREATE OR REPLACE FUNCTION public.fc_sha256table(text)
  RETURNS text AS
$BODY$
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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.fc_sha256table(text)
  OWNER TO postgres;

-- Function: public.fc_validarrelease(text)

-- DROP FUNCTION public.fc_validarrelease(text);

CREATE OR REPLACE FUNCTION public.fc_validarrelease(text)
  RETURNS void AS
$BODY$
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

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.fc_validarrelease(text)
  OWNER TO postgres;


