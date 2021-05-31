DROP FUNCTION IF EXISTS SERVE_REG;
DELIMITER $$
CREATE FUNCTION SERVE_REG(bbid int)
RETURNS INT
DETERMINISTIC
BEGIN  
    DECLARE l_uid,l_rid,l_bid,l_dist,l_units,l_pid INT;
    DECLARE l_address,l_status varchar(255);
    DECLARE l_unit_part,l_lat,l_longit INT;
    DECLARE l_type,l_comp varchar(255);
    DECLARE l_count,i INT DEFAULT 0;
    DECLARE tot_units INT;
    DECLARE data_obj JSON;
    DECLARE FLAG1 INT DEFAULT 0;
    DECLARE FLAG2 INT DEFAULT 0; 
    DECLARE FLAG3 INT DEFAULT 0; 
    DECLARE c1 CURSOR FOR SELECT RequestID FROM REQUESTS WHERE BloodbankID=bbid;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET FLAG1 = 1;
    OPEN c1; 
    
    blood_loop:LOOP
        FETCH c1 into l_rid;
        IF FLAG1 THEN 
            CLOSE c1;
            SET FLAG1=0;
            LEAVE blood_loop;
        END IF;
        SELECT UserID,blood_type,blood_component,Units,ParentID INTO l_uid,l_type,l_comp,l_units,l_pid FROM Requests WHERE RequestID=l_rid; 
        SELECT lat,longit INTO l_lat,l_longit FROM blood_bank WHERE BloodbankID=bbid;
        SELECT B_AVAIL_T(bbid,l_type,l_comp) INTO data_obj;
        SELECT JSON_EXTRACT(data_obj,'$.Units') INTO tot_units;
        IF tot_units < l_units THEN
            block2:BEGIN       
            DECLARE near_bank CURSOR FOR SELECT BloodbankID, ( 6371 * acos( cos( radians(l_lat) ) * cos( radians( lat ) ) * 
            cos( radians( longit ) - radians(l_longit) ) + sin( radians(l_lat) ) * 
            sin( radians( lat ) ) ) ) AS distance,Address FROM blood_bank HAVING
            distance < 25 ORDER BY distance LIMIT 0,5;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET FLAG3 = 1;
            OPEN near_bank;

            loc_loop:LOOP   
                FETCH near_bank into l_bid,l_dist,l_address;
                IF FLAG3 THEN 
                    CLOSE near_bank;
                    SET FLAG3=0;
                    LEAVE loc_loop;
                END IF;
                SET l_status="Pending";
                INSERT INTO Requests(UserID,bloodBankID,blood_type,blood_component,status,area,date_time,Units,ParentID)
                VALUES (l_uid,l_bid,l_type,l_comp,l_status,l_address,NOW(),l_units,l_pid);
            END LOOP loc_loop;
            DELETE FROM Requests WHERE RequestID=l_rid;
            END block2;
        ELSE
            block1:BEGIN
            DECLARE blood_unit CURSOR FOR Select BloodID,blood_units FROM Blood b INNER JOIN Donations d USING(DonationID) WHERE b.blood_group=l_type AND b.blood_component=l_comp AND d.BloodbankID=bbid ORDER BY b.blood_units desc;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET FLAG2 = 1;
            OPEN blood_unit;

            blood_loop2:LOOP    
                FETCH blood_unit into l_bid,l_unit_part;
                IF FLAG2 THEN
                    IF l_units = 0 THEN
                    UPDATE Requests SET status="Done" WHERE RequestID=l_rid;
                    UPDATE Requests SET status="Removed" where ParentID=l_pid;
                    SET l_count=l_count+1;
                    LEAVE blood_loop2;
                    END IF; 
                    CLOSE blood_unit;
                    SET FLAG2=0;
                    LEAVE blood_loop2;
                END IF;
                IF l_unit_part > l_units THEN 
                    SET l_unit_part=l_unit_part-l_units;
                    UPDATE Blood SET blood_units=l_unit_part WHERE BloodID=l_bid;
                    UPDATE Requests SET status="Done" WHERE RequestID=l_rid;
                    UPDATE Requests SET status="Removed" where ParentID=l_pid;
                    SET l_count=l_count+1;
                    LEAVE blood_loop2;
                END IF;
                SET l_units=l_units - l_unit_part;
                DELETE FROM Blood WHERE BloodID=l_bid;
            END LOOP blood_loop2;
            IF l_units > 0 THEN 
                UPDATE Requests SET Units=l_units WHERE RequestID=l_rid;
            END IF;
            END block1;
        END IF;
    END LOOP blood_loop;
  
    RETURN l_count;
END$$
DELIMITER ;    
