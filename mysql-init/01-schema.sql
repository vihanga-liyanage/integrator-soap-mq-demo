USE insurance;

CREATE TABLE IF NOT EXISTS applications (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id     VARCHAR(32)  NOT NULL,
  applicant_name  VARCHAR(128) NOT NULL,
  product         VARCHAR(64)  NOT NULL,
  risk_score      INT          NOT NULL,
  status          VARCHAR(32)  NOT NULL DEFAULT 'RECEIVED',
  created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- The Ballerina MySQL driver negotiates mysql_native_password
ALTER USER 'app'@'%' IDENTIFIED WITH mysql_native_password BY 'apppass';
FLUSH PRIVILEGES;
