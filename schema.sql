CREATE MODEL LLMModel INPUT(
  prompt STRING(MAX),
 ) OUTPUT(
  content STRING(MAX),
 ) REMOTE OPTIONS (
  endpoint = '//aiplatform.googleapis.com/projects/development-344820/locations/us-central1/publishers/google/models/text-bison@001',
  default_batch_size = 1
);

CREATE TABLE interests (
  interestUUID STRING(36) NOT NULL DEFAULT (GENERATE_UUID()),
  interest STRING(MAX),
) PRIMARY KEY(interestUUID);

CREATE UNIQUE INDEX UniqueInterests ON interests(interest);

CREATE TABLE user_notifications (
  userUUID STRING(36) NOT NULL,
  topicUUID STRING(36) NOT NULL,
  matched_interest STRING(MAX),
  created TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP()),
) PRIMARY KEY(userUUID, topicUUID);

CREATE TABLE users (
  userUUID STRING(36) NOT NULL DEFAULT (GENERATE_UUID()),
  email STRING(255) NOT NULL,
  is_online BOOL,
  created TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP()),
  updated TIMESTAMP NOT NULL OPTIONS (
    allow_commit_timestamp = true
  ),
) PRIMARY KEY(userUUID);

ALTER TABLE user_notifications ADD CONSTRAINT FK_user_notifications_users_B8880D6D8A070AF8_1 FOREIGN KEY(userUUID) REFERENCES users(userUUID) ON DELETE CASCADE;

CREATE INDEX UserActivity ON users(is_online) STORING (email);

CREATE UNIQUE INDEX UserAuthentication ON users(email);

CREATE TABLE topics (
  topicUUID STRING(36) NOT NULL DEFAULT (GENERATE_UUID()),
  userUUID STRING(36) NOT NULL,
  title STRING(MAX),
  created TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP()),
  category STRING(MAX),
) PRIMARY KEY(userUUID, topicUUID),
  INTERLEAVE IN PARENT users ON DELETE CASCADE;

ALTER TABLE user_notifications ADD CONSTRAINT FK_user_notifications_topics_CA375DEE544F134E_1 FOREIGN KEY(topicUUID) REFERENCES topics(topicUUID) ON DELETE CASCADE;

CREATE TABLE user_interests (
  interestUUID STRING(36) NOT NULL DEFAULT (GENERATE_UUID()),
  userUUID STRING(36) NOT NULL,
  interest STRING(MAX),
) PRIMARY KEY(userUUID, interestUUID),
  INTERLEAVE IN PARENT users ON DELETE CASCADE;
