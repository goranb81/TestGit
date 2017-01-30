
------------------------------------------------------------
CREATE PROCEDURE ORD.PRERACUN22 (
    IN NED1	INTEGER,
    IN NED2	INTEGER,
    IN MES	INTEGER,
    IN GOD	INTEGER,
    IN P_KURS	DECIMAL(11, 2),
    IN P_USER	VARCHAR(10) FOR SBCS DATA	CCSID EBCDIC )
  VERSION V1
  LANGUAGE SQL
  PARAMETER CCSID EBCDIC
  DYNAMIC RESULT SETS 1
  CALLED ON NULL INPUT
  MODIFIES SQL DATA
  DISABLE DEBUG MODE
  QUALIFIER APPR004
  PACKAGE OWNER APPR004
  APPLICATION ENCODING SCHEME EBCDIC
  OPTHINT ' '
  REOPT ONCE
  ROUNDING DEC_ROUND_HALF_EVEN

BEGIN
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE p_bnar integer;
  DECLARE p_bsta integer;
  DECLARE p_nkup char(60);
  DECLARE p_zned integer;
  DECLARE p_cenw decimal(11, 2);
  DECLARE p_vcen decimal(11, 2);
  --DECLARE p_kurs decimal(11, 2);
  ------------------------------------------------------------
  DECLARE p_bcen decimal(11, 2);
  DECLARE p_ttros decimal(8, 2);
  DECLARE pp_cenw decimal(11, 2);
  DECLARE pp_euro decimal(11, 2);
  DECLARE pp_bcen decimal(11, 2);
  DECLARE pp_ttros decimal(8, 2);
  DECLARE paritet varchar(100);
  DECLARE paritet_napomena varchar(100);
  DECLARE paritet_n varchar(100);
  DECLARE at_end int;
  DECLARE DGTT_FOUND int;
  DECLARE EOF INT DEFAULT 0;
  DECLARE temp_cur CURSOR WITH RETURN TO CALLER FOR
    select * from session.temptable;
  ------------------------------------------------------------  
  DECLARE C1 CURSOR FOR
    select t1.bnar, t1.bsta, t1.zned, t1.bcen, t1.cenw, 
	t1.ttros, t1.vcen, t3.NIME, t1.rsdcen
    from ord.qtoir t1, ord.qtord t2, PUN.QTREG t3
    where t1.bcen = 1 and t1.zgod = god
    and t1.bnar in (select bnar from ord.qtord
     where vpor = 'GU' 
    and skup in ( select skup from PUN.QTREG
    where 
	sdel not in ('DA') and 
	skup not in (7342691, 9527273 ) ))
    and t1.spro1 not in ('HBT', 'HBA')
    and t1.zned between ned1 and ned2
    and t1.BNAR = t2.BNAR and t2.SKUP = t3.SKUP 
	and t2.SLOK = t3.SLOK;
    --and zned between 45 and 48;
  
  DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' 
  SET DGTT_FOUND=1;
  drop table session.temptable;
  commit;
  DECLARE GLOBAL TEMPORARY TABLE session.temptable
 (user varchar(10), kurs decimal(11, 2), mes integer, 
 god integer, ned1 integer, ned2 integer, nkup char(60), 
 bnar integer,bsta integer, vcen decimal(11, 2), 
 bcen decimal(11, 2), cenw decimal(11, 2), 
 ttros decimal(8, 2), 
  bcen_n decimal(11, 2), cenw_n decimal(11, 2), 
  ttros_n decimal(8, 2), paritet varchar(100))
  ON COMMIT PRESERVE ROWS;
  
  OPEN C1;
  
  SET at_end = 0;
  WHILE at_end = 0 DO
    FETCH FROM C1 INTO p_bnar, p_bsta, p_zned, 
	p_bcen, p_cenw, p_ttros, p_vcen, p_nkup, pp_euro;
    if SQLCODE = 0 then
      ------------------------------------------------------------      
      --select kurs into p_kurs
      --from DEV.MESECNI_KURS where ned1 >= 45 and ned2 <= 48;
      set paritet = ''; 
      select SUBSTR(t3.nlst, 1, 3), t3.nlst insert into paritet, 
	  paritet_napomena
      from ord.qtoir t1, ord.qtnas t2, mik.qtlst t3
      where t1.bnar=p_bnar and t1.bsta=p_bsta
      and t2.bnar=t1.bnar and t2.bsta=t1.bsta and t2.slst='MVLA'
      and t3.slst=t2.slst and t3.clst=t2.clst;
                    
                    --set paritet = '';
      if (paritet IS NULL or paritet = '') then
    
    select SUBSTR(t3.nlst, 1, 3), t3.nlst insert into paritet, 
	paritet_napomena
    from ord.qtord t1, ord.qtnap t2, mik.qtlst t3
    where t1.bnar=p_bnar
    and t2.bnar=t1.bnar and t2.slst='MVLA'
    and t3.slst=t2.slst and t3.clst=t2.clst;
    end if;
    
      if (paritet = 'FCA' or paritet = 'EXW') then
        set pp_bcen = p_vcen*p_kurs;
        --set pp_cenw =p_vcen*p_kurs;
        set pp_cenw =p_vcen*p_kurs;
        set pp_ttros = 0;
     
        insert into session.temptable values (p_user, p_kurs, mes, god, 
		ned1, ned2, p_nkup, p_bnar, p_bsta, p_vcen, p_bcen, 
		p_cenw, p_ttros, pp_bcen, pp_cenw, pp_ttros, paritet_napomena);
    
      end if;
     
      if (paritet != 'FCA' and paritet != 'EXW') then
        set pp_bcen = p_vcen*p_kurs;
        --set pp_cenw = p_cenw*p_kurs;
        set pp_cenw =p_vcen*p_kurs;
        set pp_ttros = pp_bcen - pp_cenw;
        
        insert into session.temptable values (p_user, p_kurs, mes, god, ned1, 
		ned2, p_nkup, p_bnar, p_bsta, p_vcen, p_bcen, p_cenw, 
		p_ttros, pp_bcen, pp_cenw, pp_ttros, paritet_napomena);
      
      end if;
    
    else
      SET at_end = 1;
    end if;
  
  END WHILE;
  close C1;
  
  open temp_cur;
END;