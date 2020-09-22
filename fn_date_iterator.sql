CREATE OR REPLACE FUNCTION fn_date_iterator() RETURNS VOID AS $$
DECLARE rec1 RECORD;
DECLARE rec2 RECORD;
DECLARE varID bigint;
DECLARE varDate1 timestamp;
DECLARE varDate2 timestamp;

BEGIN
	 
		
		FOR rec2 IN 
			 SELECT 	
				linktable.leave_date, --leave_date
				linktable.optional_to_leave_date --optional_to_leave_date
			FROM dblink ('user=postgres password=postgres dbname=egemsdb', 
				'SELECT 
				X.employee_truancy_id, 
				X.leave_date, 
				X.leave_unit, 
				X.response, 
				X.responded_on, 
				Z.employee_code, 
				(SELECT W.employee_code FROM employees W WHERE W.id = X.actual_responder_id) AS responded_by,	
				X.details, 
				X.period,
				X.optional_to_leave_date 
				FROM employee_truancy_details X JOIN employees Z 
					ON X.employee_id = Z.id
				WHERE X.response = ''Approved'' AND X.period = 3 AND X.employee_truancy_id = 319') AS
				linktable 
				(employee_truancy_id bigint,
				leave_date timestamp with time zone,
				leave_unit double precision,
				response character varying(255),
				responded_on timestamp with time zone,
				employee_number character varying(255),
				responded_by character varying(255),
				details character varying(255),
				period bigint,
				optional_to_leave_date timestamp with time zone)      			
		LOOP
			varDate1 := rec2.leave_date;
			varDate2 := rec2.optional_to_leave_date;

			WHILE varDate1 <= varDate2
			LOOP
				RAISE NOTICE 'varDate1: %', varDate1;	
				varDate1 = varDate1 + INTERVAL '1 day';
			END LOOP;
		END LOOP;



	--EXCEPTION WHEN OTHERS THEN RAISE NOTICE '% %', SQLSTATE, SQLERRM;
END;
$$ LANGUAGE plpgsql;
