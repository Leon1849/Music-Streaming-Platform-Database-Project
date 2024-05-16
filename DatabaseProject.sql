-- Creating database
CREATE DATABASE MusicStreamingPlatform;

-- Dropping created database
-- DROP DATABASE IF EXISTS MusicStreamingPlatform;

-- Creating Types
CREATE TYPE LANGUAGE_CODE AS ENUM ('AF', 'AM', 'AR', 'AZ', 'BE', 'BG', 'BN', 'BS', 'CA', 
								   'CS', 'CY', 'DA', 'DE', 'EL', 'EN', 'EO', 'ES', 'ET', 
								   'EU', 'FA', 'FI', 'FR', 'GA', 'GL', 'GU', 'HE', 'HI', 
								   'HR', 'HU', 'HY', 'ID', 'IS', 'IT', 'JA', 'JV', 'KA', 
								   'KK', 'KM', 'KN', 'KO', 'KY', 'LA', 'LB', 'LO', 'LT', 
								   'LV', 'MG', 'MI', 'MK', 'ML', 'MN', 'MR', 'MS', 'MT', 
								   'MY', 'NB', 'NE', 'NL', 'NN', 'NO', 'OR', 'PA', 'PL', 
								   'PS', 'PT', 'RO', 'RU', 'RW', 'SE', 'SI', 'SK', 'SL', 
								   'SQ', 'SR', 'SV', 'SW', 'TA', 'TE', 'TH', 'TR', 'UK', 
								   'UR', 'UZ', 'VI', 'ZH');
-- Dropping created LANGUAGE_CODE type			
-- DROP TYPE IF EXISTS LANGUAGE_CODE;

-- Creating Tables
CREATE TABLE User_ (
    user_id INT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    firstName VARCHAR(255) NOT NULL,
    lastName VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_ VARCHAR(30) NOT NULL,
    registrationDate DATE
);

CREATE TABLE Subscription_ (
    subscription_id INT,
    subscriptionType VARCHAR(255) NOT NULL,
    price DECIMAL(10 , 2) NOT NULL,
    duration VARCHAR(99),
	user_id INT NOT NULL,
	user_email VARCHAR(99),
	FOREIGN KEY (user_id) 
		REFERENCES User_(user_id),
	PRIMARY KEY(subscription_id, user_email)
);

CREATE TABLE Artist (
    artist_id INT PRIMARY KEY,
    artistName VARCHAR(255) NOT NULL,
    nationality VARCHAR(255),
    dateOfBirth DATE
);

CREATE TABLE Award (
    award_id INT PRIMARY KEY,
    awardName VARCHAR(255) NOT NULL,
	awardCategory VARCHAR(45),
    year_ VARCHAR(30),
	awardOrganization VARCHAR(45),
	artist_id INT NOT NULL,
	FOREIGN KEY(artist_id)
		REFERENCES Artist(artist_id)
);

CREATE TABLE Review (
	review_id INT PRIMARY KEY,
	message_ VARCHAR(9999) NOT NULL,
	dateOfReview DATE,
	messageLanguage LANGUAGE_CODE NOT NULL,
	user_id INT NOT NULL,
	artist_id INT NOT NULL,
	FOREIGN KEY(artist_id) 
		REFERENCES Artist(artist_id),
	FOREIGN KEY (user_id) 
		REFERENCES User_(user_id)
);

CREATE TABLE Playlist (
    playlist_id INT PRIMARY KEY,
    playlistTitle VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    creationDate DATE,
	user_id INT NOT NULL,
	FOREIGN KEY(user_id)
		REFERENCES User_(user_id)
);

CREATE TABLE Genre (
    genre_id INT PRIMARY KEY,
    genreName VARCHAR(255) NOT NULL
);

CREATE TABLE Album (
    album_id INT PRIMARY KEY,
    albumTitle VARCHAR(255) NOT NULL,
    releaseDate DATE NOT NULL,
	artist_id INT NOT NULL,
	FOREIGN KEY(artist_id)
		REFERENCES Artist(artist_id)
);

CREATE TABLE Song (
    song_id INT PRIMARY KEY,
    songTitle VARCHAR(255) NOT NULL,
    duration FLOAT NOT NULL,
    releaseDate DATE NOT NULL,
	playlist_id INT NOT NULL,
	album_id INT NOT NULL,
	genre_id INT NOT NULL,
	artist_id INT NOT NULL,
	FOREIGN KEY(playlist_id)
		REFERENCES PLaylist(playlist_id),
	FOREIGN KEY(album_id)
		REFERENCES Album(album_id),
	FOREIGN KEY(genre_id)
		REFERENCES Genre(genre_id),
	FOREIGN KEY(artist_id)
		REFERENCES Artist(artist_id)
);

CREATE TABLE RecentlyPlayed (
	recently_played_song_id INT PRIMARY KEY,
	songDuration VARCHAR(100) NOT NULL,
	songName VARCHAR(100) NOT NULL,
	artistName VARCHAR(100) NOT NULL,
	user_id INT NOT NULL,
	FOREIGN KEY(user_id) 
		REFERENCES User_(user_id)
);

-- Dropping created tables
-- DROP TABLE IF EXISTS User_ CASCADE;
-- DROP TABLE IF EXISTS Subscription_ CASCADE;
-- DROP TABLE IF EXISTS Artist CASCADE;
-- DROP TABLE IF EXISTS Award CASCADE;
-- DROP TABLE IF EXISTS Review CASCADE;
-- DROP TABLE IF EXISTS Playlist CASCADE;
-- DROP TABLE IF EXISTS Genre CASCADE;
-- DROP TABLE IF EXISTS Album CASCADE;
-- DROP TABLE IF EXISTS Song CASCADE;
-- DROP TABLE IF EXISTS RecentlyPlayed;


-- Creating Indexing
CREATE INDEX idx_song_release_date ON Song(releaseDate);
CREATE INDEX idx_playlist_user_playlist ON Playlist(playlist_id);
CREATE INDEX idx_artist_name ON Artist(artistName);   
CREATE INDEX idx_genre_name ON Genre(genreName);
CREATE INDEX idx_user_email ON User_(email);

-- Dropping created indexes
-- DROP INDEX IF EXISTS idx_song_release_date;
-- DROP INDEX IF EXISTS idx_playlist_user_playlist;
-- DROP INDEX IF EXISTS idx_artist_name;
-- DROP INDEX IF EXISTS idx_genre_name;
-- DROP INDEX IF EXISTS idx_user_email;

-- Triggers (1st)

-- 1st trigger

-- Function for preventing deletion of artists with associated albums
CREATE OR REPLACE FUNCTION prevent_delete_artist()
RETURNS TRIGGER AS $$
DECLARE
    album_count INT;
BEGIN
    SELECT COUNT(*) INTO album_count FROM Album WHERE artist_id = OLD.artist_id;

    IF album_count > 0 THEN
        RAISE EXCEPTION 'Cannot delete artist who have at least one album.';
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to execute before deleting rows in the "Artist" table, using a specific function.
CREATE TRIGGER trigger_prevent_delete_artist
BEFORE DELETE ON Artist
FOR EACH ROW
EXECUTE FUNCTION prevent_delete_artist();

-- Dropping created function prevent_delete_artist and trigger trigger_prevent_delete_artist
-- DROP TRIGGER IF EXISTS trigger_prevent_delete_artist ON Artist;
-- DROP FUNCTION IF EXISTS prevent_delete_artist;

-- 2nd trigger

-- Function to check unique email
CREATE OR REPLACE FUNCTION ensure_unique_email()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM User_ WHERE email = NEW.email) THEN
        RAISE EXCEPTION 'Email % already exists.', NEW.email;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to ensure unique email on insert into User_
CREATE TRIGGER trigger_ensure_unique_email
BEFORE INSERT ON User_
FOR EACH ROW
EXECUTE FUNCTION ensure_unique_email();

-- Dropping created function ensure_unique_email and trigger trigger_ensure_unique_email
-- DROP TRIGGER IF EXISTS trigger_ensure_unique_email ON User_;
-- DROP FUNCTION IF EXISTS ensure_unique_email;
 
-- 3rd trigger

-- Function to check if a user already has a subscription
CREATE OR REPLACE FUNCTION prevent_multiple_subscriptions()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Subscription_
        WHERE user_id = NEW.user_id
    ) THEN
        RAISE EXCEPTION 'User with id % already has a subscription.', NEW.user_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to ensure a user has only one subscription
CREATE TRIGGER trigger_prevent_multiple_subscriptions
BEFORE INSERT ON Subscription_
FOR EACH ROW
EXECUTE FUNCTION prevent_multiple_subscriptions();

-- Dropping created function prevent_multiple_subscriptions and trigger trigger_prevent_multiple_subscriptions
-- DROP TRIGGER IF EXISTS trigger_prevent_multiple_subscriptions ON Subscription_;
-- DROP FUNCTION IF EXISTS prevent_multiple_subscriptions;

-- Insert data into User_ Table
INSERT INTO User_ (user_id, username, firstName, lastName, email, password_, registrationDate) VALUES
(101, 'susan_smith', 'Susan', 'Smith', 'susan.smith@gmail.com', 'secure123!', '2022-01-01'),
(102, 'tom_jones', 'Tom', 'Jones', 'tom.jones@yahoo.com', 'strongpassword', '2022-02-01'),
(103, 'alice_johnson', 'Alice', 'Johnson', 'alice.johnson@edu.aua.am', 'mypassword', '2022-03-01'),
(104, 'david_brown', 'David', 'Brown', 'david.brown@gmail.com', 'dontguess123', '2022-04-01'),
(105, 'julia_roberts', 'Julia', 'Roberts', 'julia.roberts@yahoo.com', 'mysecret', '2022-05-01'),
(106, 'paul_miller', 'Paul', 'Miller', 'paul.miller@gmail.com', 'correcthorsebattery', '2022-06-01'),
(107, 'linda_james', 'Linda', 'James', 'linda.james@edu.aua.am', 'newpassword', '2022-07-01'),
(108, 'michael_white', 'Michael', 'White', 'michael.white@yahoo.com', 'trustno1', '2022-08-01'),
(109, 'karen_green', 'Karen', 'Green', 'karen.green@gmail.com', 'thepassword', '2022-09-01'),
(110, 'john_davis', 'John', 'Davis', 'john.davis@edu.aua.am', 'mynewpassword', '2022-10-01'),
(111, 'lisa_clark', 'Lisa', 'Clark', 'lisa.clark@yahoo.com', 'welcome123', '2022-11-01'),
(112, 'emma_lewis', 'Emma', 'Lewis', 'emma.lewis@gmail.com', 'ch@ngemypassword', '2022-12-01'),
(113, 'richard_turner', 'Richard', 'Turner', 'richard.turner@edu.aua.am', 'simplepassword', '2023-01-01'),
(114, 'amelia_hill', 'Amelia', 'Hill', 'amelia.hill@yahoo.com', 'password456', '2023-02-01'),
(115, 'james_martin', 'James', 'Martin', 'james.martin@gmail.com', 'strongpw', '2023-03-01'),
(116, 'daniel_moore', 'Daniel', 'Moore', 'daniel.moore@yahoo.com', 'guessmypassword', '2023-04-01'),
(117, 'sophia_miller', 'Sophia', 'Miller', 'sophia.miller@edu.aua.am', 'password321', '2023-05-01'),
(118, 'lucas_king', 'Lucas', 'King', 'lucas.king@gmail.com', 'p@ssword2023', '2023-06-01'),
(119, 'isabella_hall', 'Isabella', 'Hall', 'isabella.hall@yahoo.com', 'secureme', '2023-07-01'),
(120, 'jack_jackson', 'Jack', 'Jackson', 'jack.jackson@gmail.com', 'mynewsecret', '2023-08-01'),
(121, 'charlotte_thomas', 'Charlotte', 'Thomas', 'charlotte.thomas@gmail.com', 'newpass123', '2023-09-01'),
(122, 'liam_jones', 'Liam', 'Jones', 'liam.jones@yahoo.com', 'passw0rd99', '2023-10-01'),
(123, 'mia_clark', 'Mia', 'Clark', 'mia.clark@edu.aua.am', 'letmein2023', '2023-11-01'),
(124, 'benjamin_lewis', 'Benjamin', 'Lewis', 'benjamin.lewis@gmail.com', 'notmypassword', '2023-12-01'),
(125, 'zoe_roberts', 'Zoe', 'Roberts', 'zoe.roberts@yahoo.com', 'password987', '2024-01-01'),
(126, 'oliver_white', 'Oliver', 'White', 'oliver.white@gmail.com', 'keepitsecret', '2024-02-01'),
(127, 'ava_harris', 'Ava', 'Harris', 'ava.harris@edu.aua.am', 'password!@#$', '2024-03-01'),
(128, 'elijah_smith', 'Elijah', 'Smith', 'elijah.smith@gmail.com', '123mypassword', '2024-04-01'),
(129, 'grace_williams', 'Grace', 'Williams', 'grace.williams@yahoo.com', 'newpassword1', '2024-05-01'),
(130, 'ethan_davis', 'Ethan', 'Davis', 'ethan.davis@gmail.com', 'secret2024', '2024-06-01'),
(131, 'chloe_johnson', 'Chloe', 'Johnson', 'chloe.johnson@edu.aua.am', 'letmein456', '2024-07-01'),
(132, 'noah_wilson', 'Noah', 'Wilson', 'noah.wilson@gmail.com', 'mynewpass', '2024-08-01'),
(133, 'sophia_brown', 'Sophia', 'Brown', 'sophia.brown@yahoo.com', 'simple123', '2024-09-01'),
(134, 'lucas_clark', 'Lucas', 'Clark', 'lucas.clark@gmail.com', 'guessme', '2024-10-01'),
(135, 'mia_king', 'Mia', 'King', 'mia.king@gmail.com', 'passwordABC', '2024-11-01'),
(136, 'jack_martin', 'Jack', 'Martin', 'jack.martin@edu.aua.am', 'supersecret', '2024-12-01'),
(137, 'hannah_walker', 'Hannah', 'Walker', 'hannah.walker@yahoo.com', 'secretpass', '2025-01-01'),
(138, 'mason_thompson', 'Mason', 'Thompson', 'mason.thompson@gmail.com', 'my_pass123', '2025-02-01'),
(139, 'isabella_white', 'Isabella', 'White', 'isabella.white@edu.aua.am', 'p@ssword!', '2025-03-01'),
(140, 'henry_jackson', 'Henry', 'Jackson', 'henry.jackson@gmail.com', 'anotherpass456', '2025-04-01');



-- Insert data into Artist Table
INSERT INTO Artist (artist_id, artistName, nationality, dateOfBirth) VALUES
(201, 'The Beatles', 'British', '1940-01-01'),
(202, 'The Rolling Stones', 'British', '1940-02-01'),
(203, 'Pink Floyd', 'British', '1940-03-01'),
(204, 'Led Zeppelin', 'British', '1940-04-01'),
(205, 'Queen', 'British', '1940-05-01'),
(206, 'The Who', 'British', '1940-06-01'),
(207, 'AC/DC', 'Australian', '1940-07-01'),
(208, 'Metallica', 'American', '1940-08-01'),
(209, 'Iron Maiden', 'British', '1940-09-01'),
(210, 'Black Sabbath', 'British', '1940-10-01'),
(211, 'U2', 'Irish', '1940-11-01'),
(212, 'The Doors', 'American', '1940-12-01'),
(213, 'Jimi Hendrix', 'American', '1940-01-01'),
(214, 'Nirvana', 'American', '1940-02-01'),
(215, 'David Bowie', 'British', '1940-03-01'),
(216, 'Bob Dylan', 'American', '1940-04-01'),
(217, 'The Kinks', 'British', '1940-05-01'),
(218, 'Fleetwood Mac', 'British', '1940-06-01'),
(219, 'ZZ Top', 'American', '1940-07-01'),
(220, 'The Beach Boys', 'American', '1940-08-01');

-- Insert data into Genre Table
INSERT INTO Genre (genre_id, genreName) VALUES
(301, 'Rock'),
(302, 'Pop'),
(303, 'Metal'),
(304, 'Blues'),
(305, 'Jazz'),
(306, 'Country'),
(307, 'Folk'),
(308, 'Reggae'),
(309, 'Hip Hop'),
(310, 'Classical'),
(311, 'Disco'),
(312, 'Soul'),
(313, 'Funk'),
(314, 'Techno'),
(315, 'House'),
(316, 'Punk Rock'),
(317, 'Grunge'),
(318, 'New Wave'),
(319, 'Progressive Rock'),
(320, 'Alternative Rock');

-- Insert data into Album Table
INSERT INTO Album (album_id, albumTitle, releaseDate, artist_id) VALUES
(401, 'Abbey Road', '1969-09-26', 201),
(402, 'Let It Be', '1970-05-08', 201),
(403, 'Sticky Fingers', '1971-04-23', 202),
(404, 'Let It Bleed', '1969-12-05', 202),
(405, 'The Dark Side of the Moon', '1973-03-01', 203),
(406, 'The Wall', '1979-11-30', 203),
(407, 'Led Zeppelin IV', '1971-11-08', 204),
(408, 'Led Zeppelin II', '1969-10-22', 204),
(409, 'A Night at the Opera', '1975-11-21', 205),
(410, 'News of the World', '1977-10-28', 205),
(411, 'Who''s Next', '1971-08-14', 206),
(412, 'Quadrophenia', '1973-10-26', 206),
(413, 'Back in Black', '1980-07-25', 207),
(414, 'Highway to Hell', '1979-07-27', 207),
(415, 'Master of Puppets', '1986-03-03', 208),
(416, 'Ride the Lightning', '1984-07-27', 208),
(417, 'The Number of the Beast', '1982-03-22', 209),
(418, 'Iron Maiden', '1980-04-14', 209),
(419, 'Paranoid', '1970-09-18', 210),
(420, 'Heaven and Hell', '1980-04-25', 210),
(421, 'Exile on Main St.', '1972-05-12', 202),
(422, 'Animals', '1977-01-23', 203),
(423, 'A Night at the Opera', '1975-11-21', 205),
(424, 'The Man Who Sold the World', '1970-11-04', 215),
(425, 'High Voltage', '1976-02-14', 207),
(426, 'Rubber Soul', '1965-12-03', 201),
(427, 'In the Court of the Crimson King', '1969-10-10', 203),
(428, 'Physical Graffiti', '1975-02-24', 204),
(429, 'Queen II', '1974-03-08', 205),
(430, 'Hunky Dory', '1971-12-17', 215),
(431, 'Blue Train', '1957-09-15', 205),
(432, 'Hard Rock Cafe', '1980-01-01', 220),
(433, 'Out of Our Heads', '1965-07-30', 202),
(434, 'American Idiot', '2004-09-21', 214),
(435, 'Greatest Hits', '1981-10-26', 211),
(436, 'The Soft Parade', '1969-07-18', 212),
(437, 'Paranoid', '1970-09-18', 210),
(438, 'News of the World', '1977-10-28', 206),
(439, 'Unplugged in New York', '1994-11-01', 214),
(440, 'London Calling', '1979-12-14', 218);

-- Insert data into Playlist Table
INSERT INTO Playlist (playlist_id, playlistTitle, description, creationDate, user_id) VALUES 
(501, 'Classic Rock', 'A collection of classic rock songs', '2023-03-05', 101),
(502, 'Best of Beatles', 'All-time Beatles favorites', '2023-03-15', 102),
(503, 'Metal Hits', 'Greatest metal songs', '2023-03-25', 103),
(504, 'Jazz Classics', 'All-time jazz classics', '2023-04-05', 104),
(505, 'Pop Hits', 'Popular songs through the ages', '2023-04-15', 105),
(506, 'Country Favorites', 'Top country songs', '2023-04-25', 106),
(507, 'Rock Anthems', 'Rock anthems from different eras', '2023-05-05', 107),
(508, 'Blues Legends', 'Famous blues songs', '2023-05-15', 108),
(509, 'Disco Fever', 'Top disco songs', '2023-05-25', 109),
(510, 'Soul & Funk', 'Greatest soul and funk songs', '2023-06-05', 110),
(511, 'Reggae Vibes', 'Best reggae tracks', '2023-06-15', 111),
(512, 'Hip Hop Hits', 'Classic hip hop tracks', '2023-06-25', 112),
(513, 'Classical Greats', 'Famous classical music pieces', '2023-07-05', 113),
(514, 'Techno Beats', 'Top techno songs', '2023-07-15', 114),
(515, 'House Party', 'Best house music', '2023-07-25', 115),
(516, 'Punk Rock Essentials', 'Great punk rock tracks', '2023-08-05', 116),
(517, 'Grunge Hits', 'Best grunge songs', '2023-08-15', 117),
(518, 'New Wave Favorites', 'Top new wave tracks', '2023-08-25', 118),
(519, 'Progressive Rock Classics', 'Top progressive rock songs', '2023-09-05', 119),
(520, 'Alternative Rock Gems', 'Best alternative rock tracks', '2023-09-15', 120),
(521, 'Indie Rock Hits', 'Best indie rock songs', '2023-09-25', 108),
(522, 'Garage Rock Favorites', 'Top garage rock tracks', '2023-10-05', 112),
(523, 'Dance Party', 'Best dance tracks for a party', '2023-10-15', 117),
(524, 'Lo-fi Beats', 'Relaxing lo-fi music', '2023-10-25', 115),
(525, '90s Pop Classics', 'Greatest pop hits from the 90s', '2023-11-05', 120),
(526, 'Synthwave Essentials', 'Top synthwave songs', '2023-11-15', 103),
(527, 'Folk Music', 'Famous folk songs', '2023-11-25', 101),
(528, 'Retro Hits', 'Top retro songs', '2023-12-05', 107),
(529, 'Jazz Fusion', 'Best jazz fusion tracks', '2023-12-15', 109),
(530, 'World Music', 'A selection of world music', '2023-12-25', 104),
(531, 'Experimental Sounds', 'Experimental and avant-garde music', '2024-01-05', 116),
(532, 'Electronic Vibes', 'Top electronic music tracks', '2024-01-15', 113),
(533, 'Country Classics', 'Best country music', '2024-01-25', 105),
(534, 'Latin Hits', 'Top Latin music tracks', '2024-02-05', 102),
(535, 'Reggaeton Favorites', 'Best reggaeton songs', '2024-02-15', 119),
(536, 'R&B Gems', 'Greatest R&B songs', '2024-02-25', 118),
(537, 'Classic Ballads', 'Top romantic ballads', '2024-03-05', 106),
(538, 'Soulful Voices', 'Songs with soulful voices', '2024-03-15', 114),
(539, 'Metalcore Hits', 'Top metalcore tracks', '2024-03-25', 110),
(540, 'Pop Punk Favorites', 'Best pop punk songs', '2024-04-05', 111),
(541, 'Jazz Collection', 'The best jazz tracks', '2024-04-10', 121),
(542, 'Rock Legends', 'Greatest rock songs', '2024-04-15', 122),
(543, 'Hip Hop Classics', 'Top hip hop hits', '2024-04-20', 123),
(544, 'Country Hits', 'Popular country songs', '2024-04-25', 124),
(545, 'Blues Favorites', 'Classic blues tracks', '2024-05-01', 125),
(546, 'Electronic Beats', 'Best electronic music', '2024-05-05', 126),
(547, 'Latin Vibes', 'Top Latin music', '2024-05-10', 127),
(548, 'Indie Essentials', 'Popular indie music', '2024-05-15', 128),
(549, 'Soul Collection', 'The best soul songs', '2024-05-20', 129),
(550, 'Jazz Anthems', 'Popular jazz tracks', '2024-05-25', 130),
(551, 'Country Classics', 'Top country hits', '2024-06-01', 131),
(552, 'Hip Hop Mix', 'Great hip hop songs', '2024-06-05', 132),
(553, 'Rock Essentials', 'Best rock anthems', '2024-06-10', 133),
(554, 'Indie Gems', 'Top indie songs', '2024-06-15', 134),
(555, 'Latin Hits', 'Popular Latin tracks', '2024-06-20', 135),
(556, 'Blues Legends', 'Greatest blues music', '2024-06-25', 136),
(557, 'Electronic Collection', 'Best electronic tracks', '2024-07-01', 137),
(558, 'Jazz Hits', 'Popular jazz songs', '2024-07-05', 138),
(559, 'Rock Mix', 'Top rock songs', '2024-07-10', 139),
(560, 'Country Favorites', 'The best country music', '2024-07-15', 140),
(561, 'Classical Favorites', 'Timeless classical music pieces', '2024-07-20', 126),
(562, 'Rock Anthems', 'The best rock songs', '2024-07-25', 135),
(563, 'Hip Hop Mix', 'Popular hip hop tracks', '2024-08-01', 121),
(564, 'Country Hits', 'Favorite country songs', '2024-08-05', 140),
(565, 'Soulful Grooves', 'Great soul and funk music', '2024-08-10', 127),
(566, 'Indie Collection', 'Top indie music hits', '2024-08-15', 134),
(567, 'Jazz Gems', 'Popular jazz songs', '2024-08-20', 122),
(568, 'Dance Party', 'Energetic dance tracks', '2024-08-25', 136),
(569, 'Electronic Vibes', 'Best electronic music', '2024-09-01', 125),
(570, 'Reggae Classics', 'Classic reggae tunes', '2024-09-05', 137),
(571, 'Blues Legends', 'Greatest blues tracks', '2024-09-10', 132),
(572, 'Latin Beats', 'Top Latin music', '2024-09-15', 121),
(573, 'Country Classics', 'Best country music', '2024-09-20', 139),
(574, 'Rock Legends', 'The best of classic rock', '2024-09-25', 123),
(575, 'Hip Hop Hits', 'Popular hip hop songs', '2024-10-01', 130),
(576, 'Indie Essentials', 'Top indie rock songs', '2024-10-05', 131),
(577, 'Jazz Collection', 'Smooth jazz music', '2024-10-10', 124),
(578, 'Soul Classics', 'Greatest soul songs', '2024-10-15', 127),
(579, 'Electronic Beats', 'Best electronic tracks', '2024-10-20', 133),
(580, 'Country Favorites', 'Popular country music', '2024-10-25', 128);

-- Insert data into Song Table
INSERT INTO Song (song_id, songTitle, duration, releaseDate, album_id, genre_id, playlist_id, artist_id) VALUES
(601, 'Come Together', 4.2, '1969-09-26', 401, 301, 502, 201),
(602, 'Hey Jude', 7.1, '1968-08-26', 402, 301, 502, 201),
(603, 'Brown Sugar', 3.5, '1971-04-16', 403, 301, 501, 202),
(604, 'Sympathy for the Devil', 6.2, '1968-11-05', 404, 301, 501, 202),
(605, 'Comfortably Numb', 6.1, '1979-11-30', 405, 301, 503, 203),
(606, 'Another Brick in the Wall', 3.4, '1979-11-30', 405, 301, 503, 203),
(607, 'Stairway to Heaven', 8.0, '1971-11-08', 407, 301, 501, 204),
(608, 'Whole Lotta Love', 5.3, '1969-10-22', 407, 301, 501, 204),
(609, 'Bohemian Rhapsody', 6.0, '1975-11-21', 409, 301, 501, 205),
(610, 'We Will Rock You', 2.1, '1977-10-28', 409, 301, 501, 205),
(611, 'Baba O''Riley', 5.0, '1971-08-14', 406, 301, 501, 206),
(612, 'Won''t Get Fooled Again', 8.3, '1971-08-14', 406, 301, 501, 206),
(613, 'Back in Black', 4.2, '1980-07-25', 413, 301, 501, 207),
(614, 'Highway to Hell', 3.3, '1979-07-27', 414, 301, 501, 207),
(615, 'Master of Puppets', 8.3, '1986-03-03', 415, 303, 503, 208),
(616, 'Fade to Black', 6.6, '1984-07-27', 416, 303, 503, 208),
(617, 'Run to the Hills', 3.6, '1982-03-22', 417, 303, 503, 209),
(618, 'The Number of the Beast', 4.9, '1982-03-22', 417, 303, 503, 209),
(619, 'Iron Man', 5.5, '1970-09-18', 419, 303, 503, 210),
(620, 'War Pigs', 7.6, '1970-09-18', 419, 303, 503, 210),
(621, 'Sweet Child O'' Mine', 5.6, '1987-07-21', 415, 301, 504, 207),
(622, 'Dream On', 4.3, '1973-06-27', 416, 301, 504, 211),
(623, 'Jump', 4.0, '1983-12-21', 417, 302, 505, 207),
(624, 'High Hopes', 7.5, '1994-03-28', 418, 302, 505, 203),
(625, 'Crazy Train', 4.6, '1980-09-20', 419, 303, 506, 210),
(626, 'Roundabout', 8.3, '1971-11-26', 420, 303, 506, 210),
(627, 'Smoke on the Water', 5.4, '1972-03-25', 401, 303, 506, 203),
(628, 'Sweet Home Alabama', 4.5, '1974-06-24', 402, 301, 507, 207),
(629, 'Paint It Black', 3.5, '1966-05-13', 403, 301, 507, 202),
(630, 'Purple Haze', 2.5, '1967-03-17', 404, 302, 508, 213),
(631, 'Light My Fire', 7.1, '1967-01-01', 405, 302, 508, 212),
(632, 'Whole Lotta Rosie', 5.3, '1977-03-21', 406, 303, 509, 207),
(633, 'Layla', 7.1, '1970-11-01', 407, 303, 509, 213),
(634, 'Walk This Way', 3.3, '1975-12-04', 408, 302, 510, 213),
(635, 'Black Magic Woman', 5.6, '1970-09-23', 409, 303, 510, 207),
(636, 'Under Pressure', 4.1, '1981-10-26', 410, 302, 511, 205),
(637, 'Killer Queen', 3.0, '1974-10-21', 411, 302, 511, 205),
(638, 'I Want to Break Free', 3.5, '1984-04-02', 412, 303, 512, 205),
(639, 'We Are the Champions', 3.0, '1977-10-07', 413, 303, 512, 205),
(640, 'You Give Love a Bad Name', 3.4, '1986-07-23', 414, 302, 513, 218);


-- Insert data into RecentlyPlayed Table
INSERT INTO RecentlyPlayed (recently_played_song_id, songDuration, songName, artistName, user_id) VALUES
(701, '4.2', 'Come Together', 'The Beatles', 101),
(702, '7.1', 'Hey Jude', 'The Beatles', 101),
(703, '3.5', 'Brown Sugar', 'The Rolling Stones', 102),
(704, '6.2', 'Sympathy for the Devil', 'The Rolling Stones', 102),
(705, '6.1', 'Comfortably Numb', 'Pink Floyd', 103),
(706, '3.4', 'Another Brick in the Wall', 'Pink Floyd', 103),
(707, '8.0', 'Stairway to Heaven', 'Led Zeppelin', 104),
(708, '5.3', 'Whole Lotta Love', 'Led Zeppelin', 104),
(709, '6.0', 'Bohemian Rhapsody', 'Queen', 105),
(710, '2.1', 'We Will Rock You', 'Queen', 105),
(711, '5.0', 'Baba O''Riley', 'The Who', 106),
(712, '8.3', 'Won''t Get Fooled Again', 'The Who', 106),
(713, '4.2', 'Back in Black', 'AC/DC', 107),
(714, '3.3', 'Highway to Hell', 'AC/DC', 107),
(715, '8.3', 'Master of Puppets', 'Metallica', 108),
(716, '6.6', 'Fade to Black', 'Metallica', 108),
(717, '3.6', 'Run to the Hills', 'Iron Maiden', 109),
(718, '4.9', 'The Number of the Beast', 'Iron Maiden', 109),
(719, '5.5', 'Iron Man', 'Black Sabbath', 110),
(720, '7.6', 'War Pigs', 'Black Sabbath', 110),
(721, '4.2', 'Sweet Child O'' Mine', 'Guns N'' Roses', 111),
(722, '4.3', 'Dream On', 'Aerosmith', 112),
(723, '4.0', 'Jump', 'Van Halen', 113),
(724, '7.5', 'High Hopes', 'Pink Floyd', 114),
(725, '4.6', 'Crazy Train', 'Ozzy Osbourne', 115),
(726, '8.3', 'Roundabout', 'Yes', 116),
(727, '5.4', 'Smoke on the Water', 'Deep Purple', 117),
(728, '4.5', 'Sweet Home Alabama', 'Lynyrd Skynyrd', 118),
(729, '3.5', 'Paint It Black', 'The Rolling Stones', 119),
(730, '2.5', 'Purple Haze', 'Jimi Hendrix', 120),
(731, '7.1', 'Light My Fire', 'The Doors', 121),
(732, '5.3', 'Whole Lotta Rosie', 'AC/DC', 122),
(733, '7.1', 'Layla', 'Derek and the Dominos', 123),
(734, '3.3', 'Walk This Way', 'Aerosmith', 124),
(735, '5.6', 'Black Magic Woman', 'Santana', 125),
(736, '4.1', 'Under Pressure', 'Queen', 126),
(737, '3.0', 'Killer Queen', 'Queen', 127),
(738, '3.5', 'I Want to Break Free', 'Queen', 128),
(739, '3.0', 'We Are the Champions', 'Queen', 129),
(740, '3.4', 'You Give Love a Bad Name', 'Bon Jovi', 130),
(741, '6.1', 'Comfortably Numb', 'Pink Floyd', 131),
(742, '3.3', 'Hey Jude', 'The Beatles', 132),
(743, '5.5', 'Iron Man', 'Black Sabbath', 133),
(744, '4.2', 'Sweet Home Alabama', 'Lynyrd Skynyrd', 134),
(745, '5.6', 'Roundabout', 'Yes', 135),
(746, '3.4', 'Jump', 'Van Halen', 136),
(747, '8.3', 'Stairway to Heaven', 'Led Zeppelin', 137),
(748, '6.2', 'Fade to Black', 'Metallica', 138),
(749, '3.5', 'Paint It Black', 'The Rolling Stones', 139),
(750, '4.0', 'Smoke on the Water', 'Deep Purple', 140),
(751, '7.1', 'Light My Fire', 'The Doors', 111),
(752, '6.1', 'Comfortably Numb', 'Pink Floyd', 112),
(753, '8.0', 'Whole Lotta Love', 'Led Zeppelin', 113),
(754, '4.5', 'Sweet Home Alabama', 'Lynyrd Skynyrd', 114),
(755, '7.1', 'Layla', 'Derek and the Dominos', 115),
(756, '3.3', 'Brown Sugar', 'The Rolling Stones', 116),
(757, '8.3', 'Stairway to Heaven', 'Led Zeppelin', 117),
(758, '4.6', 'Crazy Train', 'Ozzy Osbourne', 118),
(759, '6.2', 'Fade to Black', 'Metallica', 119),
(760, '3.5', 'Iron Man', 'Black Sabbath', 120);

-- Insert data into Review Table
INSERT INTO Review (review_id, message_, dateOfReview, messageLanguage, user_id, artist_id) VALUES 
(801, 'Amazing song!', '2024-01-01', 'EN', 101, 201),
(802, 'Fantastic performance', '2024-01-02', 'EN', 102, 202),
(803, 'Legendary album', '2024-01-03', 'EN', 103, 203),
(804, 'Outstanding guitar solos', '2024-01-04', 'EN', 104, 204),
(805, 'Greatest hits', '2024-01-05', 'EN', 105, 205),
(806, 'Unforgettable voice', '2024-01-06', 'EN', 106, 206),
(807, 'Perfect concert', '2024-01-07', 'EN', 107, 207),
(808, 'Phenomenal energy', '2024-01-08', 'EN', 108, 208),
(809, 'Incredible live show', '2024-01-09', 'EN', 109, 209),
(810, 'Superb drumming', '2024-01-10', 'EN', 110, 210),
(811, 'The best of rock', '2024-01-11', 'EN', 111, 211),
(812, 'The best in town', '2024-01-12', 'EN', 112, 212),
(813, 'Iconic band', '2024-01-13', 'EN', 113, 213),
(814, 'A historic performance', '2024-01-14', 'EN', 114, 214),
(815, 'An extraordinary voice', '2024-01-15', 'EN', 115, 215),
(816, 'Impressive compositions', '2024-01-16', 'EN', 116, 216),
(817, 'Timeless hits', '2024-01-17', 'EN', 117, 217),
(818, 'An unforgettable experience', '2024-01-18', 'EN', 118, 218),
(819, 'Great band energy', '2024-01-19', 'EN', 119, 219),
(820, 'A top-notch performance', '2024-01-20', 'EN', 120, 220);

-- Insert data into Award Table
INSERT INTO Award (award_id, awardName, awardCategory, year_, awardOrganization, artist_id) VALUES 
(901, 'Grammy Award', 'Best Album', 1974, 'Recording Academy', 201),
(902, 'Grammy Award', 'Best Song', 1975, 'Recording Academy', 202),
(903, 'Grammy Award', 'Best Band', 1976, 'Recording Academy', 203),
(904, 'Grammy Award', 'Best Performance', 1977, 'Recording Academy', 204),
(905, 'Grammy Award', 'Best Rock Song', 1978, 'Recording Academy', 205),
(906, 'Grammy Award', 'Best Metal Album', 1979, 'Recording Academy', 206),
(907, 'Grammy Award', 'Best New Artist', 1980, 'Recording Academy', 207),
(908, 'Grammy Award', 'Album of the Year', 1981, 'Recording Academy', 208),
(909, 'Grammy Award', 'Song of the Year', 1982, 'Recording Academy', 209),
(910, 'Grammy Award', 'Best Live Performance', 1983, 'Recording Academy', 210),
(911, 'MTV Music Award', 'Best Music Video', 1984, 'MTV', 211),
(912, 'MTV Music Award', 'Best Performance', 1985, 'MTV', 212),
(913, 'MTV Music Award', 'Best Group', 1986, 'MTV', 213),
(914, 'Brit Award', 'Best British Group', 1987, 'British Phonographic Industry', 214),
(915, 'Brit Award', 'Best British Album', 1988, 'British Phonographic Industry', 215),
(916, 'Brit Award', 'Best British Song', 1989, 'British Phonographic Industry', 216),
(917, 'Billboard Music Award', 'Top Rock Album', 1990, 'Billboard', 217),
(918, 'Billboard Music Award', 'Top Rock Artist', 1991, 'Billboard', 218),
(919, 'Billboard Music Award', 'Top Metal Album', 1992, 'Billboard', 219),
(920, 'Billboard Music Award', 'Top Metal Artist', 1993, 'Billboard', 220);

-- Insert data into Subscription_ table
INSERT INTO Subscription_ (subscription_id, subscriptionType, price, duration, user_id, user_email) VALUES
(1001, 'Weekly Basic', 2.99, '7 days', 101, 'susan.smith@gmail.com'),
(1001, 'Weekly Basic', 2.99, '7 days', 121, 'charlotte.thomas@gmail.com'),
(1001, 'Weekly Basic', 2.99, '7 days', 140, 'henry.jackson@gmail.com'),
(1001, 'Weekly Basic', 2.99, '7 days', 110, 'john.davis@edu.aua.am'),
(1001, 'Weekly Basic', 2.99, '7 days', 135, 'mia.king@gmail.com'),
(1002, 'Weekly Standard', 3.99, '7 days', 102, 'tom.jones@yahoo.com'),
(1003, 'Weekly Deluxe', 5.99, '7 days', 103, 'alice.johnson@edu.aua.am'),
(1003, 'Weekly Deluxe', 5.99, '7 days', 129, 'grace.williams@yahoo.com'),
(1004, 'Weekly Premium', 6.99, '7 days', 104, 'david.brown@gmail.com'),
(1004, 'Weekly Premium', 6.99, '7 days', 138, 'mason.thompson@gmail.com'),
(1005, 'Weekly Elite', 7.99, '7 days', 105, 'julia.roberts@yahoo.com'),

(1006, 'Monthly Basic', 9.99, '30 days', 106, 'paul.miller@gmail.com'),
(1007, 'Monthly Standard', 11.99, '30 days', 107, 'linda.james@edu.aua.am'),
(1008, 'Monthly Deluxe', 12.99, '30 days', 108, 'michael.white@yahoo.com'),
(1009, 'Monthly Premium', 14.99, '30 days', 109, 'karen.green@gmail.com'),
(1010, 'Monthly Elite', 19.99, '30 days', 124, 'benjamin.lewis@gmail.com'),
(1010, 'Monthly Elite', 19.99, '30 days', 122, 'liam.jones@yahoo.com'),
(1010, 'Monthly Elite', 19.99, '30 days', 137, 'hannah.walker@yahoo.com'),

(1011, 'Quarterly Basic', 19.99, '90 days', 111, 'lisa.clark@yahoo.com'),
(1012, 'Quarterly Standard', 24.99, '90 days', 112, 'emma.lewis@gmail.com'),
(1013, 'Quarterly Deluxe', 29.99, '90 days', 113, 'richard.turner@edu.aua.am'),
(1014, 'Quarterly Premium', 34.99, '90 days', 114, 'amelia.hill@yahoo.com'),
(1014, 'Quarterly Premium', 34.99, '90 days', 120, 'jack.jackson@gmail.com'),
(1015, 'Quarterly Elite', 49.99, '90 days', 115, 'james.martin@gmail.com'),
(1015, 'Quarterly Elite', 49.99, '90 days', 125, 'zoe.roberts@yahoo.com'),
(1015, 'Quarterly Elite', 49.99, '90 days', 127, 'ava.harris@edu.aua.am'),
(1015, 'Quarterly Elite', 49.99, '90 days', 133, 'sophia.brown@yahoo.com'),
(1015, 'Quarterly Elite', 49.99, '90 days', 134, 'lucas.clark@gmail.com'),
(1015, 'Quarterly Elite', 49.99, '90 days', 130, 'ethan.davis@gmail.com'),
(1015, 'Quarterly Elite', 49.99, '90 days', 132, 'noah.wilson@gmail.com'),


(1016, 'Yearly Basic', 99.99, '365 days', 116, 'daniel.moore@yahoo.com'),
(1017, 'Yearly Standard', 109.99, '365 days', 117, 'sophia.miller@edu.aua.am'),
(1018, 'Yearly Deluxe', 119.99, '365 days', 118, 'lucas.king@gmail.com'),
(1019, 'Yearly Premium', 129.99, '365 days', 119, 'isabella.hall@yahoo.com'),
(1020, 'Yearly Elite', 199.99, '365 days', 123, 'mia.clark@edu.aua.am'),
(1020, 'Yearly Elite', 199.99, '365 days', 126, 'oliver.white@gmail.com'),
(1020, 'Yearly Elite', 199.99, '365 days', 128, 'elijah.smith@gmail.com'),
(1020, 'Yearly Elite', 199.99, '365 days', 131, 'chloe.johnson@edu.aua.am'),
(1020, 'Yearly Elite', 199.99, '365 days', 136, 'jack.martin@edu.aua.am'),
(1020, 'Yearly Elite', 199.99, '365 days', 139, 'isabella.white@edu.aua.am');

-- Extra Testing the Triggers

-- Trigger 1
-- When trigger is active and runned, here we should get ERROR
-- ERROR:  Cannot delete artist who have at least one album.
DELETE FROM Artist WHERE artist_id = 210;

-- Trigger 2
-- This query should succeed as we do not have user with 'johnDiaz1299@gmail.com'.
INSERT INTO User_ (user_id, username, firstName, lastName, email, password_, registrationDate) VALUES
(141, 'john_diaz', 'John', 'Diaz', 'johnDiaz1299@gmail.com', 'very_secure_password', '2020-01-01');

-- This query should not succeed as we do  have user with 'johnDiaz1299@gmail.com', it will throw ERROR.
-- ERROR:  Email johnDiaz1299@gmail.com already exists.
INSERT INTO User_ (user_id, username, firstName, lastName, email, password_, registrationDate) VALUES
(142, 'johndiaz', 'John', 'Diaz', 'johnDiaz1299@gmail.com', 'password1234567890', '2020-09-01');

-- Trigger 3
-- It will throw error, as USER with ID 112 already has subscription
-- ERROR:  User with id 112 already has a subscription.
INSERT INTO Subscription_ (subscription_id, subscriptionType, price, duration, user_id) VALUES
(1012, 'Yearly Premium', 119.99, '365 days', 112);


-- Queries
-- 1 
-- Query selects the top 7 longest songs, showing their title and duration in minutes.
SELECT 
    songTitle AS "Song Title", duration AS "Duration In Minutes"
FROM
    Song
ORDER BY duration 
DESC
LIMIT 7;

-- 2
-- Query fetches user details like ID, username, first and last names, 
-- along with their playlist titles, using a LEFT JOIN.
SELECT 
    u.user_id AS "User ID",
    u.username AS "Username",
    u.firstName AS "User first name",
    u.lastName AS "User last name",
    p.playlistTitle AS "Playlist Title"
FROM
    User_ u
        LEFT JOIN
    Playlist p ON u.user_id = p.user_id;

-- 3
-- Query fetches album titles, artist names, and release dates for albums 
-- from 1952 onward, in ascending order.
SELECT 
    a.albumTitle AS "Album Title",
	ar.artistName AS "Artist Name",
	a.releaseDate AS "Release Date"
FROM
    Album a
        INNER JOIN
    Artist ar ON a.artist_id = ar.artist_id
WHERE
    EXTRACT(YEAR FROM a.releaseDate) >= 1952
ORDER BY a.releaseDate 
ASC;

-- 4
-- Query finds distinct awards, listing award ID, name, year, artist name, 
-- song and album titles, ordered by award ID.
SELECT DISTINCT
    aw.award_id AS "Award ID",
    aw.awardName AS "Award Name",
    aw.year_ AS "Award Year",
    ar.artistName AS "Artist Name",
    s.songTitle AS "Song Title",
    al.albumTitle AS "Album Title"
FROM
    Award aw
        JOIN
    Artist ar ON aw.artist_id = ar.artist_id
        JOIN
    Album al ON ar.artist_id = al.artist_id
        JOIN
    Song s ON al.album_id = s.album_id
ORDER BY aw.award_id;

-- 5
-- Query finds unique subscription types and prices, then counts the number 
-- of subscriptions for each.
SELECT 
	DISTINCT subscriptionType AS "Subscription Type",
	price AS "Price",
	COUNT(subscriptionType) AS "Subscription Type Count"
FROM 
	Subscription_
GROUP BY 
	subscriptionType, 
	price;

-- 6
-- Query selects usernames and subscription types for users with a 
-- "Yearly Elite" subscription, using a JOIN.
SELECT 
    u.username AS "Username",
	s.subscriptionType AS "Subscription Type"
FROM
    User_ u
JOIN
    Subscription_ s ON u.user_id = s.user_id
WHERE
    s.subscriptionType = 'Yearly Elite';
    
-- 7
-- Query selects distinct user IDs, usernames, playlist IDs, 
-- and titles for playlists with "Rock" in the title.
SELECT DISTINCT
    u.user_id AS "User ID",
	u.username AS "Username",
	p.playlist_id AS "Playlist ID",
	p.playlistTitle AS "Playlist Title"
FROM
    User_ u
        JOIN
    Playlist p ON u.user_id = p.user_id
WHERE
    p.playlistTitle 
LIKE '%Rock%';

-- 8
-- Query selects song titles, release dates, and genre names for 
-- songs released between 1970 and 1980.
SELECT 
	s.songTitle AS "Song Title",
	s.releaseDate AS "Release Date", 
	gen.genreName AS "Genre Name"
FROM 
	Song s,
	Genre gen
WHERE 
	gen.genre_id = s.genre_id
AND EXTRACT
	(YEAR FROM s.releaseDate) BETWEEN 1970 AND 1980
ORDER BY 
	s.releaseDate 
DESC;
	
-- 9
-- Query selects artist names, nationalities, and award years, with awards 
-- sorted by year in descending order.
SELECT 
	ar.artistName AS "Artist Name",
	ar.nationality AS "Artist Nationality",
	aw.year_ AS "Award Year"
FROM 
	Artist ar, 
	Award aw
WHERE 
	aw.artist_id = ar.artist_id
ORDER BY 
	aw.year_ 
DESC;

-- 10
-- Query counts awards by artist nationality, grouping by nationality 
-- and ordering by the award count in descending order.
SELECT 
	ar.nationality AS "Artist Nationality",
	COUNT(aw.award_id) AS "Award Count"
FROM 
	Artist ar
JOIN 
	Award aw 
ON 
	ar.artist_id = aw.artist_id
GROUP BY 
	ar.nationality
ORDER BY 
	"Award Count"
DESC;

-- 11
-- Query selects the top 10 artists by total song plays.
SELECT 
	ar.artistName AS "Artist Name", 
	COUNT(*) AS "Total Song Plays"
FROM 
	Song s
JOIN 
	Artist ar ON s.artist_id = ar.artist_id
GROUP BY 
	ar.artistName
ORDER BY 
	"Total Song Plays" 
DESC
LIMIT 10;

-- 12
-- Query selects the top five artists by album count, counting distinct albums and ordering by album count in descending order.
SELECT 
	ar.artistName AS "Artist Name",
	COUNT(DISTINCT al.album_id) AS "Album Count"
FROM  
	Artist ar
JOIN 
	Album al
ON ar.artist_id = al.artist_id
GROUP BY 
	ar.artistName
ORDER BY 
	"Album Count" DESC
LIMIT 5;

-- 13
-- Query calculates the total revenue from all subscriptions.
SELECT 
	SUM(Subscription_.price) AS "Total Revenue"
FROM 
	Subscription_;
	
-- 14
-- Query finds the minimum and maximum subscription prices.
SELECT 
    MIN(price) AS "Minimum Price",
    MAX(price) AS "Maximum Price"
FROM 
    Subscription_;

-- 15
-- Query finds the average song duration.
SELECT 
    AVG(s.duration) AS "Average Song Duration"
FROM 
    Song s;
	
-- 16
-- Query fetches the most recent 10 songs played by users, showing user full names, song details, and duration.
SELECT 
	u.firstName || ' ' || u.lastName AS "User Full Name",
    songName AS "Recently Played Song",
    artistName AS "Artist",
    songDuration AS "Duration"
FROM 
    RecentlyPlayed rp
JOIN
	User_ u 
ON
	u.user_id = rp.user_id
ORDER BY 
    recently_played_song_id DESC
LIMIT 10;  


-- Functions 

-- 1st function
-- Function returns playlist titles for a specified user ID.
CREATE OR REPLACE FUNCTION GetUserPlaylistNames(userId INT)
RETURNS TABLE(playlistTitle VARCHAR(255)) AS $$
BEGIN
    RETURN QUERY
    SELECT pl.playlistTitle
    FROM User_ u
    JOIN Playlist pl
    ON u.user_id = pl.user_id
    WHERE u.user_id = userId;
END;
$$ LANGUAGE plpgsql;

-- Query retrieves all playlist titles for the user with ID 140
SELECT * 
FROM GetUserPlaylistNames(140);

-- Dropping function GetUserPlaylistNames;

-- DROP FUNCTION IF EXISTS GetUserPlaylistNames;

-- 2nd function
-- Function counts the number of songs by a specific artist, returning the total song count.
CREATE OR REPLACE FUNCTION GetArtistSongCount(input_artist_id INT)
RETURNS INT AS $$
DECLARE
    song_count INT;
BEGIN
    SELECT COUNT(*) INTO song_count 
	FROM Song s
	WHERE s.artist_id = input_artist_id;
    RETURN song_count;
END; 
$$ LANGUAGE plpgsql;

-- Query returns the total number of songs for the artist with ID 213.
SELECT GetArtistSongCount(213);

-- Dropping function GetArtistSongCount;

-- DROP FUNCTION IF EXISTS GetArtistSongCount;

-- 3rd function
-- Function calculates and returns the average duration of all songs.
CREATE OR REPLACE FUNCTION GetAverageSongDuration()
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    avg_duration DECIMAL(10, 2);
BEGIN
    SELECT AVG(duration) INTO avg_duration FROM Song;
    RETURN avg_duration;
END; 
$$ LANGUAGE plpgsql;

-- Query retrieves the average song duration.
SELECT GetAverageSongDuration();

-- Dropping function GetAverageSongDuration;

-- DROP FUNCTION IF EXISTS GetAverageSongDuration;

-- 4th function
-- Function updates a user's password based on their email
-- returns TRUE if updated, otherwise FALSE.
CREATE OR REPLACE FUNCTION UpdatePasswordByEmail(user_email VARCHAR(255), new_password VARCHAR(255))
RETURNS BOOLEAN AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM User_ WHERE email = user_email) THEN
        UPDATE User_
        SET password_ = new_password
        WHERE email = user_email;
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Query retrieves all information for a user whose email is 'alice.johnson@edu.aua.am'.
SELECT * 
FROM User_ 
WHERE email = 'alice.johnson@edu.aua.am';

-- Query calls the function UpdatePasswordByEmail to update the password 
-- for the user with the email 'alice.johnson@edu.aua.am' to 'mypasswordCHANGED'.
SELECT UpdatePasswordByEmail('alice.johnson@edu.aua.am', 'mypasswordCHANGED')

-- Query retrieves all information for a user whose email is 'alice.johnson@edu.aua.am'.
 
SELECT * 
FROM User_ 
WHERE email = 'alice.johnson@edu.aua.am';

-- Dropping function UpdatePasswordByEmail;

-- DROP FUNCTION IF EXISTS UpdatePasswordByEmail;

-- 5th function
-- Function returns the total duration of songs in a given playlist, or 0 if none are found.
CREATE OR REPLACE FUNCTION GetPlaylistTotalDuration(input_playlist_id INT)
RETURNS DECIMAL AS $$
DECLARE
    total_duration DECIMAL;
BEGIN
    SELECT SUM(s.duration) INTO total_duration
    FROM Song s
    WHERE s.playlist_id = input_playlist_id;

    IF total_duration IS NULL THEN
        RETURN 0;
    END IF;

    RETURN total_duration;
END;
$$ LANGUAGE plpgsql;

-- Query retrieves the total duration of all songs in the playlist with ID 502.
SELECT GetPlaylistTotalDuration(502);

-- Dropping function GetPlaylistTotalDuration;

-- DROP FUNCTION IF EXISTS GetPlaylistTotalDuration;

-- 6th function 
-- Function deletes a user by ID, returning TRUE if successful or FALSE if user doesn't exist.
CREATE OR REPLACE FUNCTION DeleteUserById(userId INT)
RETURNS BOOLEAN AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM User_ WHERE user_id = userId) THEN
        DELETE FROM User_ WHERE user_id = userId;
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Inserts example user in User_ table
INSERT INTO User_ (user_id, username, firstName, lastName, email, password_, registrationDate) VALUES
(181, 'example_user', 'name', 'surname', 'namesurname1234@gmail.com', 'unknown!89', '2020-01-01'); 

-- Checking if example user exists in table User_
SELECT * FROM User_ WHERE user_id = 181;

-- Calls DeleteUserById(181) to delete recently created user with id 181
SELECT DeleteUserById(181);

-- Checking if user with id 181 is deleted
SELECT * FROM User_ WHERE user_id = 181;

-- Dropping function DeleteUserById;

-- DROP FUNCTION IF EXISTS DeleteUserById;


-- Views

-- 1st view 
-- Creating a view which is displaying artist names, album titles, release dates, song count, and total song duration.
CREATE OR REPLACE VIEW ArtistAlbumOverview AS
SELECT
    a.artistName AS "Artist Name",
    alb.albumTitle AS "Album Title",
    alb.releaseDate AS "Release Date",
    COUNT(s.song_id) AS "Total Songs",
    SUM(s.duration) AS "Total Duration"
FROM
    Artist a
JOIN
    Album alb ON a.artist_id = alb.artist_id
LEFT JOIN
    Song s ON alb.album_id = s.album_id
GROUP BY
    a.artistName,
    alb.albumTitle,
    alb.releaseDate
ORDER BY
    a.artistName,
    alb.releaseDate;

-- Query retrieves all data from the ArtistAlbumOverview view.
SELECT * FROM ArtistAlbumOverview;

-- Dropping created view ArtistAlbumOverview;

-- DROP VIEW IF EXISTS ArtistAlbumOverview;

-- 2nd view
-- Creating a view which is displaying 10 longest songs along with their details.
CREATE VIEW LongestSongsView AS
    SELECT 
        s.songTitle AS "Song Title",
        s.duration AS "Song Duration",
        ar.artistName AS "Artist Name",
        al.albumTitle AS "Album Title"
    FROM
        Song s
            LEFT JOIN
        Artist ar ON s.artist_id = ar.artist_id
            LEFT JOIN
        Album al ON s.album_id = al.album_id
    ORDER BY s.duration DESC
    LIMIT 10;
	    
-- Query retrieves all data from the LongestSongsView view.
SELECT * FROM LongestSongsView;

-- Dropping created view LongestSongsView;

-- DROP VIEW IF EXISTS LongestSongsView;

-- 3rd view
-- Creates a view listing artists and their award information, 
-- including award name, year, and artist details.
CREATE VIEW ArtistAwardsView AS
    SELECT 
        a.artist_id AS "Artist ID",
        a.artistName AS "Artist Name",
        a.nationality AS "Nationality",
        a.dateOfBirth AS "Date Of Birth",
        aw.award_id AS "Award ID",
        aw.awardName AS "Award Name",
        aw.year_ AS "Award Year"
    FROM
        Artist a
            LEFT JOIN
        Award aw ON A.artist_id = AW.artist_id;
		
-- Query retrieves all data from the ArtistAwardsView view.
SELECT * FROM ArtistAwardsView;

-- Dropping created view ArtistAwardsView;

-- DROP VIEW IF EXISTS ArtistAwardsView;

-- 4th view 
-- Creates a view showing the top three genres based on song count, 
-- ordered by the number of songs.
CREATE VIEW TopGenres AS
    SELECT 
        gen.genreName AS "Genre Name",
		COUNT(s.song_id) AS "Song Count"
    FROM
        Genre gen
            LEFT JOIN
        Song s 
			ON gen.genre_id = s.genre_id
    GROUP BY gen.genre_id , gen.genreName
    ORDER BY "Song Count" DESC
    LIMIT 3;
	
-- Query retrieves all data from the TopGenres view.
SELECT * FROM TopGenres;

-- Dropping created view TopGenres;

-- DROP VIEW IF EXISTS TopGenres;