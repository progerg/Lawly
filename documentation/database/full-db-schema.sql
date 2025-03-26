-- Создание всех ENUM типов
CREATE TYPE field_type AS ENUM (
    'date',
    'str',
    'number'
);

CREATE TYPE payment_status AS ENUM (
    'processing',
    'error',
    'success'
);

CREATE TYPE document_status AS ENUM (
    'started',
    'completed',
    'error'
);

CREATE TYPE message_sender_type AS ENUM (
    'user',
    'ai',
    'lawyer'
);

CREATE TYPE message_status AS ENUM (
    'sent',
    'delivered',
    'read'
);

CREATE TYPE chat_type AS ENUM (
    'ai',
    'lawyer'
);

CREATE TYPE lawyer_request_status AS ENUM (
    'pending',
    'in_progress',
    'completed'
);

CREATE TYPE document_review_status AS ENUM (
    'pending',
    'in_progress',
    'completed',
    'rejected'
);

-- Таблица пользователей
CREATE TABLE users (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email varchar(255) NOT NULL UNIQUE,
    password_hash text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    name varchar(255) NOT NULL
);

-- Таблица юристов
CREATE TABLE lawyers (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    created_at timestamp without time zone DEFAULT now()
);

-- Таблица тарифов
CREATE TABLE tariffs (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(255) NOT NULL,
    description text,
    price integer NOT NULL,
    consultations_count integer DEFAULT 0,
    ai_access boolean DEFAULT false,
    custom_templates boolean DEFAULT false,
    unlimited_docs boolean DEFAULT false
);

-- Таблица подписок
CREATE TABLE subscribes (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint REFERENCES users(id) ON DELETE CASCADE,
    tariff_id bigint REFERENCES tariffs(id) ON DELETE CASCADE,
    start_date timestamp without time zone NOT NULL,
    end_date timestamp without time zone NOT NULL,
    count_lawyer integer DEFAULT 0,
    consultations_total integer DEFAULT 0,
    consultations_used integer DEFAULT 0,
    can_use_ai boolean DEFAULT false,
    can_create_custom_templates boolean DEFAULT false,
    unlimited_documents boolean DEFAULT false
);

-- Таблица платежей
CREATE TABLE payments (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    created_at timestamp without time zone DEFAULT now(),
    amount integer NOT NULL,
    status payment_status NOT NULL,
    user_id bigint REFERENCES users(id) ON DELETE CASCADE,
    subscribe_id bigint REFERENCES subscribes(id) ON DELETE CASCADE
);

-- Таблица документов (типы базовых документов)
CREATE TABLE documents (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(255) NOT NULL,
    name_ru varchar(255) NOT NULL,
    link text NOT NULL,
    description text
);

-- Таблица шаблонов
CREATE TABLE templates (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(255) NOT NULL,
    name_ru varchar(255) NOT NULL,
    description text,
    image_url text
);

-- Таблица полей
CREATE TABLE fields (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(255) NOT NULL,
    type field_type NOT NULL,
    document_id bigint REFERENCES documents(id) ON DELETE CASCADE,
    template_id bigint REFERENCES templates(id) ON DELETE CASCADE
);

-- Таблица процесса создания документов
CREATE TABLE document_creation (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    template_id bigint REFERENCES templates(id) ON DELETE SET NULL,
    status document_status NOT NULL,
    start_date timestamp without time zone NOT NULL DEFAULT now(),
    end_date timestamp without time zone,
    custom_name text,
    error_message text
);

-- Таблица сообщений
CREATE TABLE messages (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    chat_type chat_type NOT NULL,
    sender_type message_sender_type NOT NULL,
    sender_id bigint, -- Заполняется, если sender_type = 'lawyer'
    content text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    status message_status DEFAULT 'sent',
    read_at timestamp without time zone
);

-- Таблица обращений к юристам
CREATE TABLE lawyer_requests (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lawyer_id bigint REFERENCES lawyers(id),
    status lawyer_request_status NOT NULL DEFAULT 'pending',
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    document_content text, -- Текст сгенерированного документа от пользователя
    document_url text, -- Ссылка на документ в S3
    estimated_response_time timestamp without time zone,
    note text -- Внутренние заметки юриста
);

-- Таблица проверки документов юристами
CREATE TABLE document_reviews (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lawyer_id bigint REFERENCES lawyers(id),
    document_content text NOT NULL, -- Текст сгенерированного документа от пользователя
    document_url text, -- Ссылка на документ в S3
    status document_review_status NOT NULL DEFAULT 'pending',
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    feedback text,
    corrected_document_url text -- Ссылка на исправленный документ в S3
);

-- Создание всех индексов
CREATE INDEX idx_messages_user_id_chat_type ON messages(user_id, chat_type);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_lawyer_requests_user_id ON lawyer_requests(user_id);
CREATE INDEX idx_lawyer_requests_lawyer_id ON lawyer_requests(lawyer_id);
CREATE INDEX idx_lawyer_requests_status ON lawyer_requests(status);
CREATE INDEX idx_document_reviews_user_id ON document_reviews(user_id);
CREATE INDEX idx_document_reviews_lawyer_id ON document_reviews(lawyer_id);
CREATE INDEX idx_document_reviews_status ON document_reviews(status);
CREATE INDEX idx_subscribes_user_id ON subscribes(user_id);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_fields_document_id ON fields(document_id);
CREATE INDEX idx_fields_template_id ON fields(template_id);
CREATE INDEX idx_document_creation_user_id ON document_creation(user_id);
CREATE INDEX idx_document_creation_template_id ON document_creation(template_id);
CREATE INDEX idx_document_creation_status ON document_creation(status);

-- Триггерные функции
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Триггеры для автоматического обновления времени изменения
CREATE TRIGGER update_lawyer_requests_modtime
BEFORE UPDATE ON lawyer_requests
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_document_reviews_modtime
BEFORE UPDATE ON document_reviews
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- Триггер для обновления счетчика использованных консультаций
CREATE OR REPLACE FUNCTION increment_consultations_used()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE subscribes
    SET consultations_used = consultations_used + 1
    WHERE user_id = NEW.user_id AND end_date > now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER after_lawyer_request_insert
AFTER INSERT ON lawyer_requests
FOR EACH ROW
EXECUTE FUNCTION increment_consultations_used();
