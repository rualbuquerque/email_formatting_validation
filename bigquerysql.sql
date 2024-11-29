WITH layer1 AS (

SELECT t1.id
      , t1.email as original_email
      ,IF(INSTR(email, '@') > 0, 
                  LOWER(TRIM(CONCAT(REGEXP_replace(SUBSTR(REGEXP_REPLACE(NORMALIZE(email, NFD),r"\pM",''), 1,
                        INSTR(REGEXP_REPLACE(NORMALIZE(email, NFD),r"\pM",'') , '@') - 1),' ',''),'@',
                        REGEXP_EXTRACT(SUBSTR(REGEXP_REPLACE   (NORMALIZE(email, NFD),r"\pM",'') , 
                        INSTR(REGEXP_REPLACE(NORMALIZE(email, NFD),r"\pM",'') , '@') + 1), '[a-zA-Z]+.+[a-zA-Z]')))), --end of true
                  LOWER(TRIM(REGEXP_REPLACE(NORMALIZE(email, NFD),r"\pM",'') )) --end of false
      ) as email_clean_s1  --normalizing and replacing accented letter by equivalent letter without the accentuation

FROM   `project.dataset.table` t1 


)

------------ 1st validation - email

,first_validation AS (

SELECT id
  , original_email
  , email_clean_s1
  , IF(REGEXP_CONTAINS(email_clean_s1, r'^[a-zA-Z0-9._+-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}$') and email_clean_s1 not like '% %' and email_clean_s1 not like '%,%' and email_clean_s1 not like '%:%' and email_clean_s1 not like '%;%' and email_clean_s1 not like '%+%' , 'Valid', 'Invalid')  AS email_validation_1  
  ,REGEXP_CONTAINS(email_clean_s1, r'[^a-zA-Z0-9.@_-]') AS not_allowed_characters


FROM   layer1


)

,second_validation AS 
(SELECT id
    , original_email
    ,first_validation.email_clean_s1
    ,CASE  when email_validation_1 = 'Valid' then lower(email_clean_s1)
      WHEN (email_validation_1 = 'Invalid' and not_allowed_characters is true)
            THEN REGEXP_REPLACE(REGEXP_REPLACE(email_clean_s1, r'[^\w@.-]', ''),' ','')
      ELSE email_clean_s1
    END AS clean_email_2

from first_validation

)


SELECT 
 clean_email_2 as email_std
, IF(REGEXP_CONTAINS(clean_email_2, r'^[a-zA-Z0-9._+-]+@[a-zA-Z0-9.-]+.[a-zA-Z]{2,}$') 
                  and clean_email_2 not like '% %' 
                  and clean_email_2 not like '%,%' 
                  and clean_email_2 not like '%+%' 
                  AND NET.REG_DOMAIN(clean_email_2)
                  is not null and (STRPOS(clean_email_2, '@') - 1) >1 
                  and (REGEXP_CONTAINS(clean_email_2, r'^[^a-zA-Z0-9]+@') is false), true, false)  AS is_email_valid
, NET.REG_DOMAIN(clean_email_2) as domain_clean

FROM second_validation 
