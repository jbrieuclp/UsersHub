SET search_path = utilisateurs, pg_catalog;


----------
--TABLES--
----------
CREATE TABLE IF NOT EXISTS t_tags (
    id_tag integer NOT NULL,
    id_tag_type integer NOT NULL,
    tag_code character varying(25),
    tag_name character varying(255),
    tag_label character varying(255),
    tag_desc text,
    date_insert timestamp without time zone,
    date_update timestamp without time zone
);
COMMENT ON TABLE t_tags IS 'Permet de créer des étiquettes ou tags ou labels, qu''il est possible d''attacher à différents objects de la base. Cela peut permettre par exemple de créer des groupes ou des listes d''utilisateurs';

DO
$$
BEGIN
CREATE SEQUENCE t_tags_id_tag_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
EXCEPTION WHEN duplicate_table THEN
        -- do nothing, it's already there
END
$$;
ALTER SEQUENCE t_tags_id_tag_seq OWNED BY t_tags.id_tag;
ALTER TABLE ONLY t_tags ALTER COLUMN id_tag SET DEFAULT nextval('t_tags_id_tag_seq'::regclass);


CREATE TABLE IF NOT EXISTS bib_tag_types (
    id_tag_type integer NOT NULL,
    tag_type_name character varying(100) NOT NULL,
    tag_type_desc character varying(255) NOT NULL
);
COMMENT ON TABLE bib_tag_types IS 'Permet de définir le type du tag';


CREATE TABLE IF NOT EXISTS cor_tags_relations (
    id_tag_l integer NOT NULL,
    id_tag_r integer NOT NULL,
    relation_type character varying(255) NOT NULL
);
COMMENT ON TABLE cor_tags_relations IS 'Permet de définir des relations nn entre tags en affectant des étiquettes à des tags';

CREATE TABLE IF NOT EXISTS cor_role_tag (
    id_role integer NOT NULL,
    id_tag integer NOT NULL
);
COMMENT ON TABLE cor_role_tag IS 'Permet d''attacher des étiquettes à des roles. Par exemple pour créer des listes d''observateurs';

CREATE TABLE IF NOT EXISTS cor_organism_tag (
    id_organism integer NOT NULL,
    id_tag integer NOT NULL
);
COMMENT ON TABLE cor_organism_tag IS 'Permet d''attacher des étiquettes à des organismes';


CREATE TABLE IF NOT EXISTS cor_application_tag (
    id_application integer NOT NULL,
    id_tag integer NOT NULL
);
COMMENT ON TABLE cor_organism_tag IS 'Permet d''attacher des étiquettes à des applications';


CREATE TABLE IF NOT EXISTS cor_app_privileges (
    id_tag_action integer NOT NULL,
    id_tag_object integer NOT NULL,
    id_application integer NOT NULL,
    id_role integer NOT NULL
);
COMMENT ON TABLE cor_app_privileges IS 'Cette table centrale, permet de gérer les droits d''usage des données en fonction du profil de l''utilisateur. Elle établi une correspondance entre l''affectation de tags génériques du schéma utilisateurs à un role pour une application avec les droits d''usage  (CREATE, READ, UPDATE, VALID, EXPORT, DELETE) et le type des données GeoNature (MY DATA, MY ORGANISM DATA, ALL DATA)';


DO
$$
BEGIN
ALTER TABLE bib_organismes ADD COLUMN id_parent integer;
ALTER TABLE t_applications ADD COLUMN id_parent integer;
EXCEPTION WHEN duplicate_column  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO $$ 
    BEGIN
        ALTER TABLE utilisateurs.t_roles ADD COLUMN pass_plus text;
    EXCEPTION
        WHEN duplicate_column THEN RAISE NOTICE 'column "pass_plus" already exists in "utilisateurs.t_roles".';
    END
$$;
----------------
--PRIMARY KEYS--
----------------
ALTER TABLE ONLY t_tags ADD CONSTRAINT pk_t_tags PRIMARY KEY (id_tag);

ALTER TABLE ONLY bib_tag_types ADD CONSTRAINT pk_bib_tag_types PRIMARY KEY (id_tag_type);

ALTER TABLE ONLY cor_tags_relations ADD CONSTRAINT pk_cor_tags_relations PRIMARY KEY (id_tag_l, id_tag_r);

ALTER TABLE ONLY cor_organism_tag ADD CONSTRAINT pk_cor_organism_tag PRIMARY KEY (id_organism, id_tag);

ALTER TABLE ONLY cor_role_tag ADD CONSTRAINT pk_cor_role_tag PRIMARY KEY (id_role, id_tag);

ALTER TABLE ONLY cor_application_tag ADD CONSTRAINT pk_cor_application_tag PRIMARY KEY (id_application, id_tag);

ALTER TABLE ONLY cor_app_privileges ADD CONSTRAINT pk_cor_app_privileges PRIMARY KEY (id_tag_object, id_tag_action, id_application, id_role);


------------
--TRIGGERS--
------------

DO
$$
BEGIN
CREATE TRIGGER tri_modify_date_insert_t_tags BEFORE INSERT ON t_tags FOR EACH ROW EXECUTE PROCEDURE modify_date_insert();
EXCEPTION WHEN duplicate_object  THEN
        -- do nothing, it's already there
END
$$;

DO
$$
BEGIN
CREATE TRIGGER tri_modify_date_update_t_tags BEFORE UPDATE ON t_tags FOR EACH ROW EXECUTE PROCEDURE modify_date_update();
EXCEPTION WHEN duplicate_object  THEN
        -- do nothing, it's already there
END
$$;

----------------
--FOREIGN KEYS--
----------------
DO
$$
BEGIN
ALTER TABLE ONLY bib_organismes ADD CONSTRAINT fk_bib_organismes_id_parent FOREIGN KEY (id_parent) REFERENCES bib_organismes(id_organisme) ON UPDATE CASCADE;
ALTER TABLE ONLY t_applications ADD CONSTRAINT fk_t_applications_id_parent FOREIGN KEY (id_parent) REFERENCES t_applications(id_application) ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;
ALTER TABLE ONLY t_tags ADD CONSTRAINT fk_t_tags_id_tag_type FOREIGN KEY (id_tag_type) REFERENCES bib_tag_types(id_tag_type) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_tags_relations ADD CONSTRAINT fk_cor_tags_relations_id_tag_l FOREIGN KEY (id_tag_l) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_tags_relations ADD CONSTRAINT fk_cor_tags_relations_id_tag_r FOREIGN KEY (id_tag_r) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_organism_tag ADD CONSTRAINT fk_cor_organism_tag_id_organism FOREIGN KEY (id_organism) REFERENCES bib_organismes(id_organisme) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_organism_tag ADD CONSTRAINT fk_cor_organism_tag_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_role_tag ADD CONSTRAINT fk_cor_role_tag_id_role FOREIGN KEY (id_role) REFERENCES t_roles(id_role) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_role_tag ADD CONSTRAINT fk_cor_role_tag_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_application_tag ADD CONSTRAINT fk_cor_application_tag_t_applications_id_application FOREIGN KEY (id_application) REFERENCES t_applications(id_application) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_application_tag ADD CONSTRAINT fk_cor_application_tag_t_tags_id_tag FOREIGN KEY (id_tag) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_app_privileges ADD CONSTRAINT fk_cor_app_privileges_id_tag_object FOREIGN KEY (id_tag_object) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_app_privileges ADD CONSTRAINT fk_cor_app_privileges_id_tag_action FOREIGN KEY (id_tag_action) REFERENCES t_tags(id_tag) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_app_privileges ADD CONSTRAINT fk_cor_app_privileges_id_application FOREIGN KEY (id_application) REFERENCES t_applications(id_application) ON UPDATE CASCADE;
ALTER TABLE ONLY cor_app_privileges ADD CONSTRAINT fk_cor_app_privileges_id_role FOREIGN KEY (id_role) REFERENCES t_roles(id_role) ON UPDATE CASCADE;


---------
--VIEWS--
---------
DROP VIEW IF EXISTS v_userslist_forall_menu;
CREATE OR REPLACE VIEW v_userslist_forall_menu AS
 SELECT a.groupe,
    a.id_role,
    a.identifiant,
    a.nom_role,
    a.prenom_role,
    (upper(a.nom_role::text) || ' '::text) || a.prenom_role::text AS nom_complet,
    a.desc_role,
    a.pass,
    a.pass_plus,
    a.email,
    a.id_organisme,
    a.organisme,
    a.id_unite,
    a.remarques,
    a.pn,
    a.session_appli,
    a.date_insert,
    a.date_update,
    a.id_menu
   FROM ( SELECT u.groupe,
            u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            u.organisme,
            u.id_unite,
            u.remarques,
            u.pn,
            u.session_appli,
            u.date_insert,
            u.date_update,
            c.id_menu
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_role_menu c ON c.id_role = u.id_role
          WHERE u.groupe = false
        UNION
         SELECT u.groupe,
            u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            u.organisme,
            u.id_unite,
            u.remarques,
            u.pn,
            u.session_appli,
            u.date_insert,
            u.date_update,
            c.id_menu
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
             JOIN utilisateurs.cor_role_menu c ON c.id_role = g.id_role_groupe
          WHERE u.groupe = false) a;

DROP VIEW IF EXISTS v_userslist_forall_applications;
CREATE OR REPLACE VIEW v_userslist_forall_applications AS 
 SELECT a.groupe,
    a.id_role,
    a.identifiant,
    a.nom_role,
    a.prenom_role,
    a.desc_role,
    a.pass,
    a.pass_plus,
    a.email,
    a.id_organisme,
    a.organisme,
    a.id_unite,
    a.remarques,
    a.pn,
    a.session_appli,
    a.date_insert,
    a.date_update,
    max(a.id_droit) AS id_droit_max,
    a.id_application
   FROM ( SELECT u.groupe,
            u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            u.organisme,
            u.id_unite,
            u.remarques,
            u.pn,
            u.session_appli,
            u.date_insert,
            u.date_update,
            c.id_droit,
            c.id_application
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_role_droit_application c ON c.id_role = u.id_role
          WHERE u.groupe = false
        UNION
         SELECT u.groupe,
            u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            u.organisme,
            u.id_unite,
            u.remarques,
            u.pn,
            u.session_appli,
            u.date_insert,
            u.date_update,
            c.id_droit,
            c.id_application
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
             JOIN utilisateurs.cor_role_droit_application c ON c.id_role = g.id_role_groupe
          WHERE u.groupe = false) a
  GROUP BY a.groupe, a.id_role, a.identifiant, a.nom_role, a.prenom_role, a.desc_role, a.pass, a.pass_plus, a.email, a.id_organisme, a.organisme, a.id_unite, a.remarques, a.pn, a.session_appli, a.date_insert, a.date_update, a.id_application;

DROP VIEW IF EXISTS v_usersaction_forall_gn_modules;
CREATE OR REPLACE VIEW utilisateurs.v_usersaction_forall_gn_modules AS 
 WITH p_user_tag AS (
         SELECT u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            c_1.id_tag_action,
            c_1.id_tag_object,
            c_1.id_application
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_app_privileges c_1 ON c_1.id_role = u.id_role
          WHERE u.groupe = false
        ), p_groupe_tag AS (
         SELECT u.id_role,
            u.identifiant,
            u.nom_role,
            u.prenom_role,
            u.desc_role,
            u.pass,
            u.pass_plus,
            u.email,
            u.id_organisme,
            c_1.id_tag_action,
            c_1.id_tag_object,
            c_1.id_application
           FROM utilisateurs.t_roles u
             JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role
             JOIN utilisateurs.cor_app_privileges c_1 ON c_1.id_role = g.id_role_groupe
          WHERE (g.id_role_groupe IN ( SELECT DISTINCT cor_roles.id_role_groupe
                   FROM utilisateurs.cor_roles))
        ), all_users_tags AS (
         SELECT v_1.id_role,
            v_1.identifiant,
            v_1.nom_role,
            v_1.prenom_role,
            v_1.desc_role,
            v_1.pass,
            v_1.pass_plus,
            v_1.email,
            v_1.id_organisme,
            v_1.id_application,
            v_1.id_tag_action,
            v_1.id_tag_object,
            t1.tag_code AS tag_action_code,
            t2.tag_code AS tag_object_code,
            max(t2.tag_code::text) OVER (PARTITION BY v_1.id_role, v_1.id_application, t1.tag_code) AS max_tag_object_code
           FROM ( SELECT a1.id_role,
                    a1.identifiant,
                    a1.nom_role,
                    a1.prenom_role,
                    a1.desc_role,
                    a1.pass,
                    a1.pass_plus,
                    a1.email,
                    a1.id_organisme,
                    a1.id_tag_action,
                    a1.id_tag_object,
                    a1.id_application
                   FROM p_user_tag a1
                UNION
                 SELECT a2.id_role,
                    a2.identifiant,
                    a2.nom_role,
                    a2.prenom_role,
                    a2.desc_role,
                    a2.pass,
                    a2.pass_plus,
                    a2.email,
                    a2.id_organisme,
                    a2.id_tag_action,
                    a2.id_tag_object,
                    a2.id_application
                   FROM p_groupe_tag a2) v_1
             JOIN utilisateurs.t_tags t1 ON t1.id_tag = v_1.id_tag_action
             JOIN utilisateurs.t_tags t2 ON t2.id_tag = v_1.id_tag_object
        )
 SELECT v.id_role,
    v.identifiant,
    v.nom_role,
    v.prenom_role,
    v.desc_role,
    v.pass,
    v.pass_plus,
    v.email,
    v.id_organisme,
    v.id_application,
    v.id_tag_action,
    v.id_tag_object,
    v.tag_action_code,
    v.max_tag_object_code::character varying(25) AS tag_object_code
   FROM all_users_tags v
  WHERE v.max_tag_object_code = v.tag_object_code::text;


-- -------------
-- --FUNCTIONS--
-- -------------
--With action id
CREATE OR REPLACE FUNCTION can_user_do_in_module(
    myuser integer,
    mymodule integer,
    myaction integer,
    mydataextend integer)
  RETURNS boolean AS
$BODY$
-- the function say if the given user can do the requested action in the requested module on the resquested data
-- USAGE : SELECT utilisateurs.can_user_do_in_module(requested_userid,requested_actionid,requested_moduleid,requested_dataextendid);
-- SAMPLE :SELECT utilisateurs.can_user_do_in_module(2,15,14,22);
  BEGIN
    IF myaction IN (SELECT id_tag_action FROM utilisateurs.v_usersaction_forall_gn_modules WHERE id_role = myuser AND id_application = mymodule AND id_tag_object >= mydataextend) THEN
      RETURN true;
    END IF;
    RETURN false;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


--With action code
CREATE OR REPLACE FUNCTION can_user_do_in_module(
    myuser integer,
    mymodule integer,
    myaction character varying,
    mydataextend integer)
  RETURNS boolean AS
$BODY$
-- the function say if the given user can do the requested action in the requested module on the resquested data
-- USAGE : SELECT utilisateurs.can_user_do_in_module(requested_userid,requested_actioncode,requested_moduleid,requested_dataextendid);
-- SAMPLE :SELECT utilisateurs.can_user_do_in_module(2,15,14,22);
  BEGIN
    IF myaction IN (SELECT tag_action_code FROM utilisateurs.v_usersaction_forall_gn_modules WHERE id_role = myuser AND id_application = mymodule AND id_tag_object >= mydataextend) THEN
      RETURN true;
    END IF;
    RETURN false;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

--With action id
CREATE OR REPLACE FUNCTION user_max_accessible_data_level_in_module(
    myuser integer,
    myaction integer,
    mymodule integer)
  RETURNS integer AS
$BODY$
DECLARE
  themaxleveldatatype integer;
-- the function return the max accessible extend of data the given user can access in the requested module
-- USAGE : SELECT utilisateurs.user_max_accessible_data_level_in_module(requested_userid,requested_actionid,requested_moduleid);
-- SAMPLE :SELECT utilisateurs.user_max_accessible_data_level_in_module(2,14,14);
  BEGIN
  SELECT max(tag_object_code::int) INTO themaxleveldatatype FROM utilisateurs.v_usersaction_forall_gn_modules WHERE id_role = myuser AND id_application = mymodule AND id_tag_action = myaction;
  RETURN themaxleveldatatype;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

--With action code
CREATE OR REPLACE FUNCTION user_max_accessible_data_level_in_module(
    myuser integer,
    myaction character varying,
    mymodule integer)
  RETURNS integer AS
$BODY$
DECLARE
  themaxleveldatatype integer;
-- the function return the max accessible extend of data the given user can access in the requested module
-- USAGE : SELECT utilisateurs.user_max_accessible_data_level_in_module(requested_userid,requested_actioncode,requested_moduleid);
-- SAMPLE :SELECT utilisateurs.user_max_accessible_data_level_in_module(2,14,14);
  BEGIN
  SELECT max(tag_object_code::int) INTO themaxleveldatatype FROM utilisateurs.v_usersaction_forall_gn_modules WHERE id_role = myuser AND id_application = mymodule AND tag_action_code = myaction;
  RETURN themaxleveldatatype;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

CREATE OR REPLACE FUNCTION find_all_modules_childs(myidapplication integer)
  RETURNS SETOF integer AS
$BODY$
 --Param : id_application d'un module ou d'une application quelque soit son rang
 --Retourne le id_application de tous les modules enfants + le module lui-même sous forme d'un jeu de données utilisable comme une table
 --Usage SELECT utilisateurs.find_all_modules_childs(14);
 --ou SELECT * FROM utilisateurs.t_applications WHERE id_application IN(SELECT * FROM utilisateurs.find_all_modules_childs(14))
  DECLARE
    inf RECORD;
    c integer;
  BEGIN
    SELECT INTO c count(*) FROM utilisateurs.t_applications WHERE id_parent = myidapplication;
    IF c > 0 THEN
      FOR inf IN
          WITH RECURSIVE modules AS (
          SELECT a1.id_application FROM utilisateurs.t_applications a1 WHERE a1.id_application = myidapplication
          UNION ALL
          SELECT a2.id_application FROM modules m JOIN utilisateurs.t_applications a2 ON a2.id_parent = m.id_application
    )
          SELECT id_application FROM modules
  LOOP
      RETURN NEXT inf.id_application;
  END LOOP;
    END IF;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100
  ROWS 1000;

--ATTENTION cette fonction ne fonctionne pas sur une base postgres 8.x qui ne connait pas le type "json"
--Vous pouvez l'ignorer si la base n'utilise pas l'extention concernant les tags
CREATE OR REPLACE FUNCTION cruved_for_user_in_module(
    myuser integer,
    mymodule integer
  )
  RETURNS json AS
$BODY$
-- the function return user's CRUVED in the requested module
-- USAGE : SELECT utilisateurs.cruved_for_user_in_module(requested_userid,requested_moduleid);
-- SAMPLE :SELECT utilisateurs.cruved_for_user_in_module(2,14);
DECLARE
  thecruved json;
  BEGIN
	SELECT array_to_json(array_agg(row)) INTO thecruved
	FROM  (
	SELECT tag_action_code AS action, max(tag_object_code) AS level
	FROM utilisateurs.v_usersaction_forall_gn_modules
	WHERE id_role = myuser AND id_application = mymodule
	GROUP BY tag_action_code) row;
    RETURN thecruved;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
  
  
----------
-- DATA --
----------

DO
$$
BEGIN
INSERT INTO bib_tag_types(id_tag_type, tag_type_name, tag_type_desc) VALUES
(1, 'Object', 'Define a type object. Usually to define privileges on an object.')
,(2, 'Action', 'Define a type action. Usually to define privileges for an action.')
,(3, 'Privilege', 'Define a privilege level.')
,(4, 'Liste', 'Define a type liste for grouping anything.')
;
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_tags (id_tag, id_tag_type, tag_code, tag_name, tag_label, tag_desc) VALUES
(1, 3,'1','utilisateur', 'Utilisateur','Ne peut que consulter')
,(2, 3, '2', 'rédacteur', 'Rédacteur','Il possède des droit d''écriture pour créer des enregistrements')
,(3, 3, '3', 'référent', 'Référent','Utilisateur ayant des droits complémentaires au rédacteur (par exemple exporter des données ou autre)')
,(4, 3, '4', 'modérateur', 'Modérateur', 'Peu utilisé')
,(5, 3, '5', 'validateur', 'Validateur', 'Il valide bien sur')
,(6, 3, '6', 'administrateur', 'Administrateur', 'Il a tous les droits')
,(11, 2, 'C', 'create', 'Create', 'Can create/add new data')
,(12, 2, 'R', 'read', 'Read', 'Can read data')
,(13, 2, 'U', 'update', 'Update', 'Can update data')
,(14, 2, 'V', 'validate', 'Validate', 'Can validate data')
,(15, 2, 'E', 'export', 'Export', 'Can export data')
,(16, 2, 'D', 'delete', 'Delete', 'Can delete data')
,(20, 3, '0', 'nothing', 'Nothing', 'Cannot do anything')
,(21, 3, '1', 'my data', 'My data', 'Can do action only on my data')
,(22, 3, '2', 'my organism data', 'My organism data', 'Can do action only on my data and on my organism data')
,(23, 3, '3', 'all data', 'All data', 'Can do action on all data')

,(100, 4, NULL, 'observateurs flore', 'Observateurs flore','Liste des observateurs pour les protocoles flore')
,(101, 4, NULL, 'observateurs faune', 'Observateurs faune','Liste des observateurs pour les protocoles faune')
,(102, 4, NULL, 'observateurs aigle', 'Observateurs aigle', 'Liste des observateurs pour le protocole suivi de la reproduction de l''aigle royal')
;
PERFORM pg_catalog.setval('t_tags_id_tag_seq', 104, true);
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;