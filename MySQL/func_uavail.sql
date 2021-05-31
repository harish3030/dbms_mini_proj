DROP FUNCTION IF EXISTS U_AVAIL;
DELIMITER $$
CREATE FUNCTION U_AVAIL
(city varchar(255),state varchar(255),b_type varchar(255),b_comp varchar(255))
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE l_bbid INT;
    DECLARE l_name varchar(255);
    DECLARE l_address varchar(255);
    DECLARE l_sum INT;
    DECLARE l_bid INT;
    DECLARE l_unit INT;
    DECLARE temp INT;
    DECLARE data_obj JSON;
    DECLARE data_obj2 JSON;
    DECLARE FLAG1 INT DEFAULT 0;
    DECLARE FLAG2 INT DEFAULT 0; 
    DECLARE bbid CURSOR FOR SELECT BloodbankID,Name,Address FROM blood_bank WHERE City=city AND State=state;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET FLAG1 = 1;
    
    OPEN bbid;

    bbid_loop:LOOP  
        FETCH bbid into l_bbid,l_name,l_address;
        IF FLAG1 THEN
          CLOSE bbid;
           LEAVE bbid_loop;
        END IF;

           block1: BEGIN
            DECLARE blood_unit CURSOR FOR Select BloodID,blood_units FROM Blood b INNER JOIN Donations d USING(DonationID) WHERE b.blood_group=b_type AND b.blood_component=b_comp AND d.BloodbankID=l_bbid;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET FLAG2 = 1;
            OPEN blood_unit;
            
            SET l_sum=0;
            blood_loop:LOOP
                FETCH blood_unit into l_bid,l_unit;
                IF FLAG2 THEN 
                    CLOSE blood_unit;
                    SET FLAG2=0;
                    LEAVE blood_loop;
                END IF;
                SET l_sum=l_sum+l_unit;
            END LOOP blood_loop;
            END block1;
            
            SELECT JSON_MERGE(
                JSON_OBJECT('Bloodbank',l_name),
                JSON_OBJECT('Area', l_address),
                JSON_OBJECT('Units',l_sum)
            ) INTO data_obj;

            SELECT JSON_DEPTH(data_obj2) INTO temp;
            IF temp IS NULL THEN
                SET data_obj2=data_obj;
            ELSE
                SELECT JSON_ARRAY_APPEND(data_obj2,'$',data_obj) INTO data_obj2;
            END IF;
       
    END LOOP bbid_loop;  
    RETURN data_obj2;
  
END$$
DELIMITER ;
  
 


