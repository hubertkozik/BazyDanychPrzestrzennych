-- 3
CREATE ROLE ksiegowosc;
GRANT SELECT ON ALL TABLES IN SCHEMA firma To ksiegowosc;

-- 4
CREATE TABLE pracownicy(
	id_pracownika serial NOT NULL primary key,
	imie varchar(20) NOT NULL,
	nazwisko varchar(40) NOT NULL,
	adres VARCHAR(50),
	telefon varchar(9)
);

CREATE TABLE godziny(
	id_godziny serial NOT NULL primary key,
	data DATE,
	liczba_godzin int,
	id_pracownika serial NOT NULL,
	FOREIGN KEY(id_pracownika) references pracownicy(id_pracownika)
);

CREATE TABLE pensja_stanowisko(
	id_pensji serial NOT NULL primary key,
	stanowisko VARCHAR(30), 
	kwota int,
	id_premii serial unique NOT NULL
);


CREATE TABLE premia(
	id_premii serial NOT NULL primary key,
	rodzaj varchar(25),
	kwota INT
);

CREATE TABLE wynagrodzenie(
	id_wynagrodzenia varchar(5) unique NOT NULL PRIMARY KEY,
	Data DATE,
	id_pracownika serial NOT NULL,
	id_godziny serial,
	id_pensji serial,
	id_premii serial,
 	FOREIGN KEY(id_pracownika) references pracownicy(id_pracownika),
	FOREIGN KEY(id_godziny) references godziny(id_godziny),
	FOREIGN KEY(id_pensji) references pensja_stanowisko(id_pensji),
	FOREIGN KEY(id_premii) references premia(id_premii)	
);

ALTER TABLE premia
ADD FOREIGN KEY (id_premii) REFERENCES pensja_stanowisko(id_premii);

ALTER TABLE pensja_stanowisko
ADD FOREIGN KEY (id_pensji) REFERENCES pracownicy(id_pracownika);

-- 5
INSERT INTO pracownicy (imie,nazwisko,adres,telefon) 
values
('Hubert','Kozik','Wielgus','345567654'),
('Edward','Bałwan','Kraków','567923012'),
('Janusz','Polak','Warszawa','741852963'),
('Alicja','Trwała','Tarnów','654987321'),
('Mateusz','Mały','Tarnów','569831421'),
('Andrzej','Morświn','Kraków','896536487'),
('Andrzej','Długosz','Kielce','525748635'),
('Malwina','Zawadzka','Kielce','641758423'),
('Anastazja','Śledź','Kielce','566741147'),
('Wiktoria','Kochana','Tarnów','656585614');

INSERT INTO godziny(data,liczba_godzin) values 
('2020-05-07',92),
('2020-05-04',168),
('2020-05-10',100),
('2020-05-11',61),
('2020-05-05',89),
('2020-05-06',55),
('2020-05-05',121),
('2020-05-09',115),
('2020-05-11',23);

ALTER TABLE godziny ADD miesiac DATE;
--INSERT INTO godziny(miesiac) SELECT (EXTRACT(MONTH FROM data) FROM godziny;

ALTER TABLE wynagrodzenie ALTER COLUMN data TYPE varchar;

INSERT INTO pensja_stanowisko(stanowisko, kwota) values
('kierownik', 12000),
('księgowa',5700),
('asystent',3500),
('pracownik',4500),
('asystentka',4100),
('doradca',2500),
('zastępca kierownika',8600),
('HR',3100),
('tester',7500),
('sprzątaczka',3200);

INSERT INTO premia(rodzaj,kwota) values
('za dobre sprawowanie',400),
('na święta',500),
('za zapomogę',150),
('uznaniowa',350),
('kwartalna',125),
('okolicznościowa',450),
('na motywacje',150),
('za nic',250),
('na Wielkanoc',225),
('za zasługi',520);

-- 6
SELECT id_pracownika, nazwisko FROM pracownicy;
SELECT fw.id_pracownika, fp.kwota, fprem.kwota FROM wynagrodzenie fw, pensja_stanowisko fp, premia fprem
WHERE fw.id_pensji = fp.id_pensji AND fw.id_premii = fprem.id_premii AND fprem.kwota + fprem.kwota > 1000;
	
SELECT fw.id_pracownika FROM wynagrodzenie fw, pensja_stanowisko fpen
	WHERE fw.id_pensji=fpen.id_pensji AND fw.id_premii IS NULL and fpen.kwota > 1000;

SELECT * FROM pracownicy fpr WHERE fpr.imie like '%J';

SELECT fpr.imie, fpr.nazwisko FROM pracownicy fpr WHERE fpr.nazwisko like '%n%' AND fpr.imie like '%a';

SELECT fpr.imie, fpr.nazwisko FROM pracownicy fpr, godziny fgodz
	WHERE fpr.id_pracownika = fgodz.id_pracownika AND fgodz.liczba_godzin > 160;

SELECT fpr.imie, fpr.nazwisko FROM pracownicy fpr, wynagrodzenie fw, pensja_stanowisko fpen
	WHERE fpr.id_pracownika = fw.id_pracownika AND fw.id_pensji = fpen.id_pensji AND fpen.kwota > 1500 AND fpen.kwota <3000;

SELECT fpr.imie, fpr.nazwisko FROM pracownicy fpr, godziny fgodz, wynagrodzenie fw
	WHERE fpr.id_pracownika = fw.id_pracownika AND fw.id_godziny = fgodz.id_godziny AND fgodz.liczba_godzin > 160 AND fw.id_premii IS NULL;

-- 7
SELECT COUNT(*), fpen.stanowisko FROM pensja_stanowisko AS fpen
	GROUP BY fpen.stanowisko ORDER BY fpen.stanowisko DESC;
SELECT MIN(fpen.kwota), MAX(fpen.kwota) FROM pensja_stanowisko fpen 
	WHERE fpen.stanowisko = 'kierownik';

SELECT SUM(COALESCE(fpr.kwota,0))+ SUM(COALESCE(fpen.kwota,0)) AS wynagrodznie FROM wynagrodzenie fw 
	LEFT JOIN pensja_stanowisko fpen ON fw.id_pensji = fpen.id_pensji
	LEFT JOIN premia fpr ON fw.id_premii = fpr.id_premii;
	
SELECT SUM(COALESCE(fpr.kwota,0))+ SUM(COALESCE(fpen.kwota,0)) AS wynagrodznie FROM wynagrodzenie fw
	LEFT JOIN pensja_stanowisko fpen ON fw.id_pensji = fpen.id_pensji
	LEFT JOIN premia fpr ON fw.id_premii = fpr.id_premii GROUP BY fpen.stanowisko;
	
SELECT COUNT(fw.id_premii) FROM wynagrodzenie fw
	LEFT JOIN pensja_stanowisko fpen ON fw.id_pensji=fpen.id_pensji GROUP BY fpen.stanowisko;
	
DELETE
FROM  wynagrodzenie fw    
USING pensja_stanowisko fpen 
WHERE fpen.kwota < 1200 AND fw.id_pensji = fpen.id_pensji;

-- 8
ALTER TABLE pracownicy ALTER COLUMN telefon TYPE varchar(17) USING telefon::varchar;
UPDATE pracownicy fp SET telefon = '(+48) '||fp.telefon;

UPDATE pracownicy fp SET telefon=SUBSTRING(fp.telefon,1,9)||'-'||SUBSTRING(fp.telefon,10,3)||'-'||SUBSTRING(fp.telefon,13,3);

SELECT UPPER(fp.imie), UPPER(fp.nazwisko), UPPER(fp.adres), UPPER(fp.telefon), LENGTH(fp.nazwisko) 
		FROM pracownicy fp 
			ORDER BY length(fp.nazwisko) DESC LIMIT 1;
			
SELECT fp.*, fpen.kwota AS kwota FROM pracownicy fp
	   JOIN wynagrodzenie fw ON fw.id_pracownika = fp.id_pracownika 
       JOIN pensja_stanowisko fpen ON fpen.id_pensji = fw.id_pensji;

-- 9
SELECT 'Pracownik ' || fp.imie || ' ' || fp.nazwisko 
|| ' w dniu ' || fg.data
|| ' otrzymał pensje całkowitą na kwotę ' || fpen.kwota + fpr.kwota 
|| ' gdzie wynagrodzenie zasadnicze wynosiło: '|| fpen.kwota || ',a premia: ' || fpr.kwota || ', nadgodziny: ' || '0 zł' AS raport
FROM pracownicy fp
JOIN wynagrodzenie fw ON fw.id_pracownika = fp.id_pracownika 
JOIN pensja_stanowisko fpen ON fpen.id_pensji = fw.id_pensji 
JOIN premia fpr ON fpr.id_premii =fw.id_premii 
JOIN godziny fg ON fp.id_pracownika = fp.id_pracownika