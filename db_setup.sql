
CREATE TABLE tiers (
	tier_code varchar(5) primary key,
	tier_name varchar(20) not null,
	max_urls_allowed int not null,
	constraint uq_tier_name unique(tier_name)
);

CREATE TABLE users (
	user_id bigint generated by default as identity primary key,
	username varchar(64) not null,
	tier_code varchar(5),
	date_created timestamptz not null,
	constraint uq_username unique(username),
	constraint tier_constraint
		foreign key(tier_code)
		references tiers(tier_code)
		ON delete set NULL
);

CREATE TABLE urls (
	url_id bigint generated by default as identity primary key,
	user_id bigint,
	original_url text not null,
	short_url text not null,
	date_created timestamptz not null,
	constraint author foreign key(user_id) references users(user_id),
	constraint uq_original_short_url unique(original_url, short_url)
);

CREATE FUNCTION CheckIfUrlCreationAllowed(id bigint)
returns int
language plpgsql
as
$$
declare url_count int;
declare max_allowed int;
begin
	select count(urls.url_id), t.max_urls_allowed
	into url_count, max_allowed from
	users as u inner join tier as t
	on u.tier_code = t.tier_code
	inner join urls
	on u.user_id = urls.user_id
	where u.user_id = id
	group by user_id;
		
	IF (url_count >= max_allowed) THEN return 1;
	ELSE return 0;
	END IF;
end;
$$

ALTER TABLE urls 
ADD CONSTRAINT tier_check
CHECK (
	CheckIfUrlCreationAllowed(user_id) = 1
);

INSERT INTO TIERS(tier_code, tier_name, max_urls_allowed) VALUES ('T1', 'Tier 1', 100);
INSERT INTO TIERS(tier_code, tier_name, max_urls_allowed) VALUES ('T2', 'Tier 2', 50);
INSERT INTO TIERS(tier_code, tier_name, max_urls_allowed) VALUES ('T3', 'Tier 3', 25);
