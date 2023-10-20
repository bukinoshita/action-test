
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";

ALTER SCHEMA "public" OWNER TO "postgres";

CREATE EXTENSION IF NOT EXISTS "http" WITH SCHEMA "public";

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgstattuple" WITH SCHEMA "public";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."emails" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "api_key_id" "uuid",
    "team_id" "uuid" NOT NULL,
    "to" "text"[] NOT NULL,
    "from" "text" NOT NULL,
    "subject" "text" NOT NULL,
    "bcc" "text"[],
    "cc" "text"[],
    "reply_to" "text"[],
    "aws_message_id" "text",
    "last_event" "text"
);

CREATE OR REPLACE FUNCTION "public"."search_emails_v2"("keyword" "text") RETURNS SETOF "public"."emails"
    LANGUAGE "sql"
    AS $$
SELECT *
FROM emails
WHERE lower(
    array_to_string(
        emails.to || emails.subject, 
        ' '
    )
) LIKE '%' || lower(keyword) || '%'
OR keyword IS NULL
OR similarity(
    lower(
        array_to_string(
            emails.to || emails.subject, 
            ' '
        )
    ),
    lower(keyword)
) > 0.3;
$$;

CREATE OR REPLACE FUNCTION "public"."search_emails_v3"("keyword" "text", "team_id" "uuid") RETURNS SETOF "public"."emails"
    LANGUAGE "sql"
    AS $$SELECT *
FROM emails
WHERE 
  emails.team_id = team_id
  AND created_at >= (CURRENT_DATE - INTERVAL '7 days') 
  AND (
    lower(
      array_to_string(
        emails.to || emails.subject, 
        ' '
      )
    ) LIKE '%' || lower(keyword) || '%'
    OR keyword IS NULL
    OR similarity(
      lower(
        array_to_string(
          emails.to || emails.subject, 
          ' '
        )
      ),
      lower(keyword)
    ) > 0.3
  );$$;

CREATE TABLE IF NOT EXISTS "public"."api_keys" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "prefix" "text" NOT NULL,
    "short_token" "text" NOT NULL,
    "long_token_hash" "text" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "deleted" boolean DEFAULT false NOT NULL,
    "permission" "text" DEFAULT 'sending_access'::"text" NOT NULL,
    "domain_id" "uuid"
);

CREATE TABLE IF NOT EXISTS "public"."audiences" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "domain_id" "uuid",
    "deleted" boolean DEFAULT false NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."broadcasts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "audience_id" "uuid",
    "name" "text" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "deleted" boolean DEFAULT false NOT NULL,
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "html" "text",
    "subject" "text",
    "from" "text",
    "user_id" "uuid" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "sent_at" timestamp with time zone,
    "content" "jsonb",
    "cc" "text"[],
    "bcc" "text"[]
);

CREATE TABLE IF NOT EXISTS "public"."contacts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "email" "text" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "deleted" boolean DEFAULT false NOT NULL,
    "unsubscribed" boolean DEFAULT false NOT NULL,
    "audience_id" "uuid" NOT NULL,
    "first_name" "text",
    "last_name" "text"
);

CREATE TABLE IF NOT EXISTS "public"."domain_denylist" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "mx" "text"
);

CREATE TABLE IF NOT EXISTS "public"."domains" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text" NOT NULL,
    "dkim_status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "deleted" boolean DEFAULT false NOT NULL,
    "team_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "dkim_tokens" "text"[],
    "spf_status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "spf_domain" "text" NOT NULL,
    "nameserver" "text" DEFAULT 'Unidentified'::"text",
    "disable_content_storage" boolean DEFAULT false NOT NULL,
    "open_track" boolean DEFAULT false NOT NULL,
    "click_track" boolean DEFAULT false NOT NULL,
    "region" "text" DEFAULT 'us-east-1'::"text",
    "dedicated_ip" "uuid",
    "dkim_public_key" "text",
    "unsubscribe_url" boolean DEFAULT false NOT NULL,
    "risk_score" bigint,
    "dkim_private_key" "text"
);

CREATE TABLE IF NOT EXISTS "public"."email_events" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "aws_raw_payload" "json",
    "type" "text",
    "aws_message_id" "text",
    "team_id" "uuid",
    "domain_id" "uuid",
    "email_id" "uuid"
);

CREATE TABLE IF NOT EXISTS "public"."email_metadata" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "html" "text",
    "text" "text",
    "email_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."gifts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "team_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" "text",
    "address1" "text",
    "address2" "text",
    "city" "text",
    "state" "text",
    "country" "text",
    "zip" "text",
    "api_key_id" "uuid",
    "cpf" "text",
    "tshirt_size" "text"
);

CREATE TABLE IF NOT EXISTS "public"."integrations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "team_id" "uuid" NOT NULL,
    "type" "text",
    "status" "text",
    "payload" "jsonb",
    "deleted" boolean DEFAULT false
);

CREATE TABLE IF NOT EXISTS "public"."log_metadata" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "request_body" "jsonb",
    "response_body" "jsonb",
    "request_headers" "jsonb",
    "response_headers" "jsonb",
    "log_id" "uuid" NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."logs" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "team_id" "uuid",
    "request_body" "json",
    "response_body" "json",
    "endpoint" "text",
    "api_key_id" "uuid",
    "method" "text",
    "response_status" bigint,
    "request_headers" "json"
);

CREATE TABLE IF NOT EXISTS "public"."members" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "role" "text" DEFAULT 'admin'::"text" NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."react_email_contacts" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "email_address" "text"
);

ALTER TABLE "public"."react_email_contacts" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."react_email_contacts_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."react_email_test_sends" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "to" "text"[],
    "subject" "text",
    "html" "text",
    "ip" "text",
    "latitude" "text",
    "longitude" "text",
    "city" "text",
    "country" "text",
    "country_region" "text"
);

ALTER TABLE "public"."react_email_test_sends" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."react_email_test_sends_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."team_invites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "team_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "user_email" "text" NOT NULL,
    "invitee_email" "text" NOT NULL,
    "invite_sent" timestamp with time zone DEFAULT "now"() NOT NULL,
    "invite_confirmed" timestamp with time zone,
    "deleted" boolean DEFAULT false NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."teams" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "quota" integer DEFAULT 3000 NOT NULL,
    "name" "text",
    "stripe_customer_id" "text",
    "stripe_customer_email" "text",
    "dedicated_slack_channel" "text",
    "quota_retention" smallint DEFAULT '1'::smallint,
    "risk_score" smallint,
    "manual_verified" boolean DEFAULT false NOT NULL,
    "email" "text",
    "tier" "text" DEFAULT 'free'::"text" NOT NULL
);

CREATE TABLE IF NOT EXISTS "public"."webhook_endpoints" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "endpoint" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "deleted" boolean DEFAULT false,
    "status" "text" DEFAULT 'enabled'::"text" NOT NULL,
    "team_id" "uuid" NOT NULL,
    "events" "text"[],
    "svix_endpoint_id" "text"
);

ALTER TABLE ONLY "public"."api_keys"
    ADD CONSTRAINT "api_keys_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."audiences"
    ADD CONSTRAINT "audiences_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."broadcasts"
    ADD CONSTRAINT "broadcasts_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."contacts"
    ADD CONSTRAINT "contacts_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."domain_denylist"
    ADD CONSTRAINT "domain_denylist_name_key" UNIQUE ("name");

ALTER TABLE ONLY "public"."domain_denylist"
    ADD CONSTRAINT "domain_denylist_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."domains"
    ADD CONSTRAINT "domains_pkey1" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."email_events"
    ADD CONSTRAINT "email_events_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."email_metadata"
    ADD CONSTRAINT "email_metadata_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."emails"
    ADD CONSTRAINT "emails_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."gifts"
    ADD CONSTRAINT "gifts_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."integrations"
    ADD CONSTRAINT "integratuibs_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."log_metadata"
    ADD CONSTRAINT "log_metadata_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."logs"
    ADD CONSTRAINT "logs_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."members"
    ADD CONSTRAINT "members_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."react_email_contacts"
    ADD CONSTRAINT "react_email_contacts_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."react_email_test_sends"
    ADD CONSTRAINT "react_email_test_sends_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."team_invites"
    ADD CONSTRAINT "team_invites_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."webhook_endpoints"
    ADD CONSTRAINT "webhook_endpoints_pkey" PRIMARY KEY ("id");

CREATE INDEX "api_keys_team_deleted_created_idx" ON "public"."api_keys" USING "btree" ("team_id", "deleted", "created_at" DESC);

CREATE INDEX "api_keys_token_deleted_idx" ON "public"."api_keys" USING "btree" ("short_token", "long_token_hash", "deleted");

CREATE INDEX "domains_name_team_id_deleted_dkim_status_spf_status_idx" ON "public"."domains" USING "btree" ("name", "team_id", "deleted", "dkim_status", "spf_status");

CREATE INDEX "domains_team_deleted_created_idx" ON "public"."domains" USING "btree" ("team_id", "deleted", "created_at" DESC);

CREATE INDEX "email_events_idx" ON "public"."email_events" USING "btree" ("aws_message_id", "type", "id");

CREATE INDEX "email_events_type_idx" ON "public"."email_events" USING "btree" ("type");

CREATE INDEX "emails_aws_message_id_last_event_idx" ON "public"."emails" USING "btree" ("aws_message_id", "last_event");

CREATE INDEX "emails_team_created_idx" ON "public"."emails" USING "btree" ("team_id", "created_at" DESC);

CREATE INDEX "idx_teams_id_risk_score_manual_verified" ON "public"."teams" USING "btree" ("risk_score", "manual_verified") WHERE ("manual_verified" = false);

CREATE INDEX "logs_team_created_idx" ON "public"."logs" USING "btree" ("team_id", "created_at" DESC);

ALTER TABLE ONLY "public"."api_keys"
    ADD CONSTRAINT "api_keys_domain_id_fkey" FOREIGN KEY ("domain_id") REFERENCES "public"."domains"("id");

ALTER TABLE ONLY "public"."api_keys"
    ADD CONSTRAINT "api_keys_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id");

ALTER TABLE ONLY "public"."api_keys"
    ADD CONSTRAINT "api_keys_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");

ALTER TABLE ONLY "public"."audiences"
    ADD CONSTRAINT "audiences_domain_id_fkey" FOREIGN KEY ("domain_id") REFERENCES "public"."domains"("id");

ALTER TABLE ONLY "public"."audiences"
    ADD CONSTRAINT "audiences_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id");

ALTER TABLE ONLY "public"."broadcasts"
    ADD CONSTRAINT "broadcasts_audience_id_fkey" FOREIGN KEY ("audience_id") REFERENCES "public"."audiences"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."broadcasts"
    ADD CONSTRAINT "broadcasts_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id");

ALTER TABLE ONLY "public"."broadcasts"
    ADD CONSTRAINT "broadcasts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");

ALTER TABLE ONLY "public"."contacts"
    ADD CONSTRAINT "contacts_audience_id_fkey" FOREIGN KEY ("audience_id") REFERENCES "public"."audiences"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."contacts"
    ADD CONSTRAINT "contacts_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id");

ALTER TABLE ONLY "public"."domains"
    ADD CONSTRAINT "domains_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id");

ALTER TABLE ONLY "public"."domains"
    ADD CONSTRAINT "domains_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id");

ALTER TABLE ONLY "public"."email_events"
    ADD CONSTRAINT "email_events_domain_id_fkey" FOREIGN KEY ("domain_id") REFERENCES "public"."domains"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."email_events"
    ADD CONSTRAINT "email_events_email_id_fkey" FOREIGN KEY ("email_id") REFERENCES "public"."emails"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."email_events"
    ADD CONSTRAINT "email_events_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."email_metadata"
    ADD CONSTRAINT "email_metadata_email_id_fkey" FOREIGN KEY ("email_id") REFERENCES "public"."emails"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."emails"
    ADD CONSTRAINT "emails_api_key_id_fkey" FOREIGN KEY ("api_key_id") REFERENCES "public"."api_keys"("id") ON DELETE SET NULL NOT VALID;

ALTER TABLE ONLY "public"."emails"
    ADD CONSTRAINT "emails_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."gifts"
    ADD CONSTRAINT "gifts_api_key_id_fkey" FOREIGN KEY ("api_key_id") REFERENCES "public"."api_keys"("id");

ALTER TABLE ONLY "public"."integrations"
    ADD CONSTRAINT "integrations_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id");

ALTER TABLE ONLY "public"."log_metadata"
    ADD CONSTRAINT "log_metadata_log_id_fkey" FOREIGN KEY ("log_id") REFERENCES "public"."logs"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."logs"
    ADD CONSTRAINT "logs_api_key_id_fkey" FOREIGN KEY ("api_key_id") REFERENCES "public"."api_keys"("id");

ALTER TABLE ONLY "public"."logs"
    ADD CONSTRAINT "logs_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id");

ALTER TABLE ONLY "public"."members"
    ADD CONSTRAINT "members_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."members"
    ADD CONSTRAINT "members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."team_invites"
    ADD CONSTRAINT "team_invites_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."team_invites"
    ADD CONSTRAINT "team_invites_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."webhook_endpoints"
    ADD CONSTRAINT "webhook_endpoints_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id");

CREATE POLICY "All access on API keys based on team id" ON "public"."api_keys" USING (("team_id" IN ( SELECT "members"."team_id"
   FROM "public"."members"
  WHERE ("auth"."uid"() = "members"."user_id"))));

REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT ALL ON SCHEMA "public" TO PUBLIC;
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."http"("request" "public"."http_request") TO "postgres";
GRANT ALL ON FUNCTION "public"."http"("request" "public"."http_request") TO "anon";
GRANT ALL ON FUNCTION "public"."http"("request" "public"."http_request") TO "authenticated";
GRANT ALL ON FUNCTION "public"."http"("request" "public"."http_request") TO "service_role";

GRANT ALL ON FUNCTION "public"."http_delete"("uri" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_delete"("uri" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_delete"("uri" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_delete"("uri" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_get"("uri" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_get"("uri" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_get"("uri" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_get"("uri" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_head"("uri" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_head"("uri" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_head"("uri" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_head"("uri" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_header"("field" character varying, "value" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_header"("field" character varying, "value" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_header"("field" character varying, "value" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_header"("field" character varying, "value" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_patch"("uri" character varying, "content" character varying, "content_type" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_patch"("uri" character varying, "content" character varying, "content_type" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_patch"("uri" character varying, "content" character varying, "content_type" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_patch"("uri" character varying, "content" character varying, "content_type" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_post"("uri" character varying, "content" character varying, "content_type" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_post"("uri" character varying, "content" character varying, "content_type" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_post"("uri" character varying, "content" character varying, "content_type" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_post"("uri" character varying, "content" character varying, "content_type" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_put"("uri" character varying, "content" character varying, "content_type" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_put"("uri" character varying, "content" character varying, "content_type" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_put"("uri" character varying, "content" character varying, "content_type" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_put"("uri" character varying, "content" character varying, "content_type" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_reset_curlopt"() TO "postgres";
GRANT ALL ON FUNCTION "public"."http_reset_curlopt"() TO "anon";
GRANT ALL ON FUNCTION "public"."http_reset_curlopt"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_reset_curlopt"() TO "service_role";

GRANT ALL ON FUNCTION "public"."http_set_curlopt"("curlopt" character varying, "value" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_set_curlopt"("curlopt" character varying, "value" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_set_curlopt"("curlopt" character varying, "value" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_set_curlopt"("curlopt" character varying, "value" character varying) TO "service_role";

GRANT ALL ON TABLE "public"."emails" TO "postgres";
GRANT ALL ON TABLE "public"."emails" TO "anon";
GRANT ALL ON TABLE "public"."emails" TO "authenticated";
GRANT ALL ON TABLE "public"."emails" TO "service_role";

GRANT ALL ON FUNCTION "public"."search_emails_v2"("keyword" "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."search_emails_v2"("keyword" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."search_emails_v2"("keyword" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_emails_v2"("keyword" "text") TO "service_role";

GRANT ALL ON FUNCTION "public"."search_emails_v3"("keyword" "text", "team_id" "uuid") TO "postgres";
GRANT ALL ON FUNCTION "public"."search_emails_v3"("keyword" "text", "team_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."search_emails_v3"("keyword" "text", "team_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_emails_v3"("keyword" "text", "team_id" "uuid") TO "service_role";

GRANT ALL ON FUNCTION "public"."urlencode"("string" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."urlencode"("string" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."urlencode"("string" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."urlencode"("string" character varying) TO "service_role";

GRANT ALL ON TABLE "public"."api_keys" TO "postgres";
GRANT ALL ON TABLE "public"."api_keys" TO "anon";
GRANT ALL ON TABLE "public"."api_keys" TO "authenticated";
GRANT ALL ON TABLE "public"."api_keys" TO "service_role";

GRANT ALL ON TABLE "public"."audiences" TO "postgres";
GRANT ALL ON TABLE "public"."audiences" TO "anon";
GRANT ALL ON TABLE "public"."audiences" TO "authenticated";
GRANT ALL ON TABLE "public"."audiences" TO "service_role";

GRANT ALL ON TABLE "public"."broadcasts" TO "postgres";
GRANT ALL ON TABLE "public"."broadcasts" TO "anon";
GRANT ALL ON TABLE "public"."broadcasts" TO "authenticated";
GRANT ALL ON TABLE "public"."broadcasts" TO "service_role";

GRANT ALL ON TABLE "public"."contacts" TO "postgres";
GRANT ALL ON TABLE "public"."contacts" TO "anon";
GRANT ALL ON TABLE "public"."contacts" TO "authenticated";
GRANT ALL ON TABLE "public"."contacts" TO "service_role";

GRANT ALL ON TABLE "public"."domain_denylist" TO "postgres";
GRANT ALL ON TABLE "public"."domain_denylist" TO "anon";
GRANT ALL ON TABLE "public"."domain_denylist" TO "authenticated";
GRANT ALL ON TABLE "public"."domain_denylist" TO "service_role";

GRANT ALL ON TABLE "public"."domains" TO "postgres";
GRANT ALL ON TABLE "public"."domains" TO "anon";
GRANT ALL ON TABLE "public"."domains" TO "authenticated";
GRANT ALL ON TABLE "public"."domains" TO "service_role";

GRANT ALL ON TABLE "public"."email_events" TO "postgres";
GRANT ALL ON TABLE "public"."email_events" TO "anon";
GRANT ALL ON TABLE "public"."email_events" TO "authenticated";
GRANT ALL ON TABLE "public"."email_events" TO "service_role";

GRANT ALL ON TABLE "public"."email_metadata" TO "postgres";
GRANT ALL ON TABLE "public"."email_metadata" TO "anon";
GRANT ALL ON TABLE "public"."email_metadata" TO "authenticated";
GRANT ALL ON TABLE "public"."email_metadata" TO "service_role";

GRANT ALL ON TABLE "public"."gifts" TO "postgres";
GRANT ALL ON TABLE "public"."gifts" TO "anon";
GRANT ALL ON TABLE "public"."gifts" TO "authenticated";
GRANT ALL ON TABLE "public"."gifts" TO "service_role";

GRANT ALL ON TABLE "public"."integrations" TO "postgres";
GRANT ALL ON TABLE "public"."integrations" TO "anon";
GRANT ALL ON TABLE "public"."integrations" TO "authenticated";
GRANT ALL ON TABLE "public"."integrations" TO "service_role";

GRANT ALL ON TABLE "public"."log_metadata" TO "postgres";
GRANT ALL ON TABLE "public"."log_metadata" TO "anon";
GRANT ALL ON TABLE "public"."log_metadata" TO "authenticated";
GRANT ALL ON TABLE "public"."log_metadata" TO "service_role";

GRANT ALL ON TABLE "public"."logs" TO "postgres";
GRANT ALL ON TABLE "public"."logs" TO "anon";
GRANT ALL ON TABLE "public"."logs" TO "authenticated";
GRANT ALL ON TABLE "public"."logs" TO "service_role";

GRANT ALL ON TABLE "public"."members" TO "postgres";
GRANT ALL ON TABLE "public"."members" TO "anon";
GRANT ALL ON TABLE "public"."members" TO "authenticated";
GRANT ALL ON TABLE "public"."members" TO "service_role";

GRANT ALL ON TABLE "public"."react_email_contacts" TO "postgres";
GRANT ALL ON TABLE "public"."react_email_contacts" TO "anon";
GRANT ALL ON TABLE "public"."react_email_contacts" TO "authenticated";
GRANT ALL ON TABLE "public"."react_email_contacts" TO "service_role";

GRANT ALL ON SEQUENCE "public"."react_email_contacts_id_seq" TO "postgres";
GRANT ALL ON SEQUENCE "public"."react_email_contacts_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."react_email_contacts_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."react_email_contacts_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."react_email_test_sends" TO "postgres";
GRANT ALL ON TABLE "public"."react_email_test_sends" TO "anon";
GRANT ALL ON TABLE "public"."react_email_test_sends" TO "authenticated";
GRANT ALL ON TABLE "public"."react_email_test_sends" TO "service_role";

GRANT ALL ON SEQUENCE "public"."react_email_test_sends_id_seq" TO "postgres";
GRANT ALL ON SEQUENCE "public"."react_email_test_sends_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."react_email_test_sends_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."react_email_test_sends_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."team_invites" TO "postgres";
GRANT ALL ON TABLE "public"."team_invites" TO "anon";
GRANT ALL ON TABLE "public"."team_invites" TO "authenticated";
GRANT ALL ON TABLE "public"."team_invites" TO "service_role";

GRANT ALL ON TABLE "public"."teams" TO "postgres";
GRANT ALL ON TABLE "public"."teams" TO "anon";
GRANT ALL ON TABLE "public"."teams" TO "authenticated";
GRANT ALL ON TABLE "public"."teams" TO "service_role";

GRANT ALL ON TABLE "public"."webhook_endpoints" TO "postgres";
GRANT ALL ON TABLE "public"."webhook_endpoints" TO "anon";
GRANT ALL ON TABLE "public"."webhook_endpoints" TO "authenticated";
GRANT ALL ON TABLE "public"."webhook_endpoints" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
