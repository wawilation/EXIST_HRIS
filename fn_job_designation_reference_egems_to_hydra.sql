CREATE OR REPLACE FUNCTION fn_job_designation_reference_egems_to_hydra() RETURNS VOID AS $$

BEGIN

		INSERT INTO records.job_designation_reference (id, deleted, code, description) 	
		SELECT 	
			NEXTVAL('hibernate_sequence'),			
			'N',
			linktable.code,
			linktable.name
		FROM dblink ('user=postgres password=postgres dbname=egemsdb', 'SELECT code, name FROM job_positions') AS
			linktable 
			(code character varying(10),
			name character varying(100));

	--EXCEPTION WHEN OTHERS THEN RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;
