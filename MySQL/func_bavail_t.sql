DROP FUNCTION IF EXISTS B_AVAIL_T;
DELIMITER $$
CREATE FUNCTION B_AVAIL_T
(bid int,b_type varchar(255),b_comp varchar(255))
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE data_obj JSON;
    DECLARE l_bbid INT;
    DECLARE l_name varchar(256);
    DECLARE l_address varchar(256);
    DECLARE l_sum INT;
    DECLARE l_bid INT;
    DECLARE l_unit INT;
    DECLARE FLAG1 INT DEFAULT 0;
    DECLARE FLAG2 INT DEFAULT 0; 

    DECLARE blood_unit CURSOR FOR Select BloodID,blood_units FROM Blood b INNER JOIN Donations d USING(DonationID) WHERE b.blood_group=b_type AND b.blood_component=b_comp AND d.BloodbankID=bid;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET FLAG2 = 1;
    SELECT Name,Address INTO l_name,l_address FROM blood_bank WHERE BloodbankID=bid;
 
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

    SELECT JSON_MERGE(
        JSON_OBJECT('Bloodbank',l_name),
        JSON_OBJECT('Area', l_address),
        JSON_OBJECT('Units',l_sum)
    ) INTO data_obj;

    RETURN data_obj;
END$$
DELIMITER ; 
  
 


