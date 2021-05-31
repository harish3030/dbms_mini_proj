DROP FUNCTION IF EXISTS B_AVAIL;
DELIMITER $$
CREATE FUNCTION B_AVAIL
(bbid INT)
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE l_bid INT;
    DECLARE l_type varchar(255);
    DECLARE l_comp varchar(255);
    DECLARE tot_units INT;
    DECLARE temp INT;
    DECLARE FLAG1 INT DEFAULT 0;
    DECLARE data_obj JSON;
    DECLARE data_obj2 JSON;
    DECLARE data_obj3 JSON;
    DECLARE blood_unit CURSOR FOR Select BloodID,blood_group,blood_component FROM Blood b INNER JOIN Donations d USING(DonationID) WHERE d.BloodbankID=bbid;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET FLAG1 = 1;      
 
    OPEN blood_unit;
   
    blood_loop:LOOP
        FETCH blood_unit into l_bid,l_type,l_comp;
        IF FLAG1 THEN 
            CLOSE blood_unit;
            SET FLAG1=0;
            LEAVE blood_loop;
        END IF;
        SELECT B_AVAIL_T(bbid,l_type,l_comp) INTO data_obj;
        SELECT JSON_EXTRACT(data_obj,'$.Units') INTO tot_units;
        
        SELECT JSON_MERGE(
            JSON_OBJECT('Bloodgroup',l_type),
            JSON_OBJECT('Bloodcomp', l_comp),
            JSON_OBJECT('Units',tot_units)
        ) INTO data_obj2;
        SELECT JSON_DEPTH(data_obj3) INTO temp;
        IF temp IS NULL THEN
            SET data_obj3=data_obj2;
        ELSE
            SELECT JSON_ARRAY_APPEND(data_obj3,'$',data_obj2) INTO data_obj3;
        END IF;
        
    END LOOP blood_loop;
    RETURN data_obj3;
END$$
DELIMITER ; 
  
 