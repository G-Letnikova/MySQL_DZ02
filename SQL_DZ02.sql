DROP DATABASE IF EXISTS vk;
CREATE DATABASE vk;
USE vk;

DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    firstname VARCHAR(50),
    lastname VARCHAR(50) COMMENT 'Фамиль', -- COMMENT на случай, если имя неочевидное
    email VARCHAR(120) UNIQUE,
 	password_hash VARCHAR(100), -- 123456 => vzx;clvgkajrpo9udfxvsldkrn24l5456345t
	phone BIGINT UNSIGNED UNIQUE, 
	
    INDEX users_firstname_lastname_idx(firstname, lastname)
) COMMENT 'юзеры';

DROP TABLE IF EXISTS `profiles`;
CREATE TABLE `profiles` (
	user_id BIGINT UNSIGNED NOT NULL UNIQUE,
    gender CHAR(1),
    birthday DATE,
	photo_id BIGINT UNSIGNED NULL,
    created_at DATETIME DEFAULT NOW(),
    hometown VARCHAR(100)
	
    -- , FOREIGN KEY (photo_id) REFERENCES media(id) -- пока рано, т.к. таблицы media еще нет
);

ALTER TABLE `profiles` ADD CONSTRAINT fk_user_id
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE -- (значение по умолчанию)
    ON DELETE RESTRICT; -- (значение по умолчанию)

DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
	id SERIAL, -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
	from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT NOW(), -- можно будет даже не упоминать это поле при вставке

    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id)
);


DROP TABLE IF EXISTS friend_requests;
CREATE TABLE friend_requests (
	-- id SERIAL, -- изменили на составной ключ (initiator_user_id, target_user_id)
	initiator_user_id BIGINT UNSIGNED NOT NULL,
    target_user_id BIGINT UNSIGNED NOT NULL,
    `status` ENUM('requested', 'approved', 'declined', 'unfriended'), # DEFAULT 'requested',
    -- `status` TINYINT(1) UNSIGNED, -- в этом случае в коде хранили бы цифирный enum (0, 1, 2, 3...)
	requested_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP, -- можно будет даже не упоминать это поле при обновлении
	
    PRIMARY KEY (initiator_user_id, target_user_id),
    FOREIGN KEY (initiator_user_id) REFERENCES users(id),
    FOREIGN KEY (target_user_id) REFERENCES users(id)-- ,
    -- CHECK (initiator_user_id <> target_user_id)
);
-- чтобы пользователь сам себе не отправил запрос в друзья
-- ALTER TABLE friend_requests 
-- ADD CHECK(initiator_user_id <> target_user_id);

DROP TABLE IF EXISTS communities;
CREATE TABLE communities(
	id SERIAL,
	name VARCHAR(150),
	admin_user_id BIGINT UNSIGNED NOT NULL,
	
	INDEX communities_name_idx(name), -- индексу можно давать свое имя (communities_name_idx)
	FOREIGN KEY (admin_user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS users_communities;
CREATE TABLE users_communities(
	user_id BIGINT UNSIGNED NOT NULL,
	community_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (user_id, community_id), -- чтобы не было 2 записей о пользователе и сообществе
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (community_id) REFERENCES communities(id)
);

DROP TABLE IF EXISTS media_types;
CREATE TABLE media_types(
	id SERIAL,
    name VARCHAR(255), -- записей мало, поэтому в индексе нет необходимости
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS media;
CREATE TABLE media(
	id SERIAL,
    media_type_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
  	body text,
    filename VARCHAR(255),
    -- file BLOB,    	
    size INT,
	metadata JSON,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (media_type_id) REFERENCES media_types(id)
);

DROP TABLE IF EXISTS likes;
CREATE TABLE likes(
	id SERIAL,
    user_id BIGINT UNSIGNED NOT NULL,
    media_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW()

    -- PRIMARY KEY (user_id, media_id) – можно было и так вместо id в качестве PK
  	-- слишком увлекаться индексами тоже опасно, рациональнее их добавлять по мере необходимости (напр., провисают по времени какие-то запросы)  

/* намеренно забыли, чтобы позднее увидеть их отсутствие в ER-диаграмме
    , FOREIGN KEY (user_id) REFERENCES users(id)
    , FOREIGN KEY (media_id) REFERENCES media(id)
*/
);

ALTER TABLE vk.likes 
ADD CONSTRAINT likes_fk 
FOREIGN KEY (media_id) REFERENCES vk.media(id);

ALTER TABLE vk.likes 
ADD CONSTRAINT likes_fk_1 
FOREIGN KEY (user_id) REFERENCES vk.users(id);

ALTER TABLE vk.profiles 
ADD CONSTRAINT profiles_fk_1 
FOREIGN KEY (photo_id) REFERENCES media(id);


-- -------------------------------------------------------------------------------------------------------------------
/*
 Домашнее задание
 - добавлены и заполнены  3 таблицы:
      коллекции пользователя (например фотоальбомы)
      таблица связей альбомов и медиа
      таблица закладок пользователя
 - заполнены таблицы users и messages
 */

DROP TABLE IF EXISTS collections;
CREATE TABLE collections(
	id SERIAL,
    user_id BIGINT UNSIGNED NOT NULL,
    status ENUM('all', 'friends', 'me_only') DEFAULT 'all',
    collection_name VARCHAR(150),
    created_at DATETIME DEFAULT NOW(),

    FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS content_collections;
CREATE TABLE content_collections(
	collection_id BIGINT UNSIGNED NOT NULL,
	media_id BIGINT UNSIGNED NOT NULL,
	
    FOREIGN KEY (collection_id) REFERENCES collections(id),
    FOREIGN KEY (media_id) REFERENCES media(id)
);

DROP TABLE IF EXISTS markers;
CREATE TABLE markers(
	id SERIAL,
    user_id BIGINT UNSIGNED NOT NULL,
    media_id BIGINT UNSIGNED NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (media_id) REFERENCES media(id)
);


-- заполнение таблиц

INSERT INTO users (firstname, lastname, email, phone) 
VALUES 
('Lori', 'Koch', 'damaris34@example.net', '9192291407'),
('Sam', 'Kuphal', 'telly.miller@example.net', '9917826312'),
('Pearl', 'Prohaska', 'xeichmann@example.net', '9136605713'),
('Ozella', 'Hauck', 'idickens@example.com', '9773438197'),
('Emmet', 'Hammes', 'qcremin@example.org', '9694110645'),
('Eleonore', 'Ward', 'antonietta.swift@example.com', '9397815776'),
('Reuben', 'Nienow', 'arlo50@example.org', '9374071116'),
('Kristina', 'Jast', 'jennifer27@example.com', '9133161481'),
('Karina', 'Doll', 'kara69@example.com', '9183161481'),
('Tina', 'Back', 'tina78@example.org', '9123161481')
;

SELECT id, firstname, lastname, email, phone FROM users;  


INSERT INTO messages (from_user_id, to_user_id, body) 
VALUES 
(1, 2, 'Hellow, Sam!'),
(1, 5, 'Hellow, Pearl!'),
(1, 3, 'Hellow, Pearl!'),
(1, 4, 'Hellow, Ozella!'),
(2, 1, 'Hellow, Lori!'),
(3, 1, 'Hi!'),
(4, 1, 'Yo!'),
(5, 1, 'I am not Pearl!'),
(2, 1, 'Lori, where do you live?'),
(4, 1, 'Hellow :)');

SELECT from_user_id, to_user_id, body FROM messages;  


INSERT INTO profiles (user_id, gender, birthday, hometown) 
VALUES 
(1, 'm', '1982-12-04', 'New York'),
(2, 'm', '1985-10-05', 'New York'),
(3, 'm', '1985-06-15', 'New York'),
(4, 'm', '1981-07-20', 'New York'),
(5, 'w', '1992-08-04', 'Los Angeles'),
(6, 'w', '1999-11-12', 'Los Angeles'), 
(7, 'w', '1998-11-25', 'Paris'),
(9, 'w', '1999-12-05', 'London'),
(10, 'w', '1997-10-10', 'Berlin');

SELECT user_id, gender, birthday, hometown from profiles;