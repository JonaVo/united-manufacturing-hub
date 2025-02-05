-- Extend the database with TimescaleDB
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-------------------- Table with all assets --------------------
CREATE TABLE IF NOT EXISTS assetTable
(
    id SERIAL PRIMARY KEY,
    assetID VARCHAR(20) NOT NULL,
    location VARCHAR(20) NOT NULL,
    customer VARCHAR(20) NOT NULL,
    unique (assetID, location, customer)
);

-------------------- TimescaleDB table for states --------------------
CREATE TABLE IF NOT EXISTS stateTable
(
    timestamp                TIMESTAMPTZ                         NOT NULL,
    asset_id            SERIAL REFERENCES assetTable (id),
    state INTEGER CHECK (state >= 0),
    UNIQUE(timestamp, asset_id)
);
-- creating hypertable
SELECT create_hypertable('stateTable', 'timestamp');

-- creating an index to increase performance
CREATE INDEX ON stateTable (asset_id, timestamp DESC);

-------------------- TimescaleDB table for counts --------------------
CREATE TABLE IF NOT EXISTS countTable
(
    timestamp                TIMESTAMPTZ                         NOT NULL,
    asset_id            SERIAL REFERENCES assetTable (id),
    count INTEGER CHECK (count > 0),
    UNIQUE(timestamp, asset_id)
);
-- creating hypertable
SELECT create_hypertable('countTable', 'timestamp');

-- creating an index to increase performance
CREATE INDEX ON countTable (asset_id, timestamp DESC);

-------------------- TimescaleDB table for process values --------------------
CREATE TABLE IF NOT EXISTS processValueTable
(
    timestamp               TIMESTAMPTZ                         NOT NULL,
    asset_id                SERIAL                              REFERENCES assetTable (id),
    valueName               TEXT                                NOT NULL,
    value                   DOUBLE PRECISION                    NULL,
    UNIQUE(timestamp, asset_id, valueName)
);
-- creating hypertable
SELECT create_hypertable('processValueTable', 'timestamp');

-- creating an index to increase performance
CREATE INDEX ON processValueTable (asset_id, timestamp DESC);

-------------------- TimescaleDB table for uniqueProduct --------------------
CREATE TABLE IF NOT EXISTS uniqueProductTable
(
    uid TEXT NOT NULL,
    asset_id            SERIAL REFERENCES assetTable (id),
    begin_timestamp_ms                TIMESTAMPTZ NOT NULL,
    end_timestamp_ms                TIMESTAMPTZ                         NOT NULL,
    product_id TEXT NOT NULL,
    is_scrap BOOLEAN NOT NULL,
    quality_class TEXT NOT NULL,
    station_id TEXT NOT NULL,
    UNIQUE(uid, asset_id, station_id),
    CHECK (begin_timestamp_ms < end_timestamp_ms)
);

-- creating an index to increase performance
CREATE INDEX ON uniqueProductTable (asset_id, uid, station_id);


-------------------- TimescaleDB table for recommendations  --------------------
CREATE TABLE IF NOT EXISTS recommendationTable
(
    uid                     TEXT                                PRIMARY KEY,
    timestamp               TIMESTAMPTZ                         NOT NULL,
    recommendationType      INTEGER                             NOT NULL,
    enabled                 BOOLEAN                             NOT NULL,
    recommendationValues    TEXT,
    diagnoseTextDE          TEXT,
    diagnoseTextEN          TEXT,
    recommendationTextDE    TEXT,
    recommendationTextEN    TEXT
);

-------------------- TimescaleDB table for shifts --------------------
-- Using btree_gist to avoid overlapping shifts
-- Source: https://gist.github.com/fphilipe/0a2a3d50a9f3834683bf
CREATE EXTENSION btree_gist;
CREATE TABLE IF NOT EXISTS shiftTable
(
    id SERIAL PRIMARY KEY,
    type INTEGER,
    begin_timestamp TIMESTAMPTZ NOT NULL,
    end_timestamp TIMESTAMPTZ,
    asset_id SERIAL REFERENCES assetTable (id),
    unique (begin_timestamp, asset_id),
    CHECK (begin_timestamp < end_timestamp),
	EXCLUDE USING gist (asset_id WITH =, tstzrange(begin_timestamp, end_timestamp) WITH &&) 
);


-------------------- TimescaleDB table for products --------------------
CREATE TABLE IF NOT EXISTS productTable
(
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(40) NOT NULL,
	asset_id SERIAL REFERENCES assetTable (id),
    time_per_unit_in_seconds REAL NOT NULL,
	UNIQUE(product_name, asset_id),
	CHECK (time_per_unit_in_seconds > 0)
);

-------------------- TimescaleDB table for orders --------------------
CREATE TABLE IF NOT EXISTS orderTable
(
    order_id SERIAL PRIMARY KEY,
    order_name VARCHAR(40) NOT NULL,
    product_id SERIAL REFERENCES productTable (product_id),
    begin_timestamp TIMESTAMPTZ,
    end_timestamp TIMESTAMPTZ,
    target_units INTEGER,
    asset_id SERIAL REFERENCES assetTable (id),
    unique (asset_id, order_id),
    CHECK (begin_timestamp < end_timestamp),
	CHECK (target_units > 0),
    EXCLUDE USING gist (asset_id WITH =, tstzrange(begin_timestamp, end_timestamp) WITH &&) WHERE (begin_timestamp IS NOT NULL AND end_timestamp IS NOT NULL)
);

-------------------- TimescaleDB table for configuration --------------------
CREATE TABLE IF NOT EXISTS configurationTable
(
    customer VARCHAR(20) PRIMARY KEY,
    MicrostopDurationInSeconds INTEGER DEFAULT 60*2,
    IgnoreMicrostopUnderThisDurationInSeconds INTEGER DEFAULT -1, --do not apply
    MinimumRunningTimeInSeconds INTEGER DEFAULT 0, --do not apply
    ThresholdForNoShiftsConsideredBreakInSeconds INTEGER DEFAULT 60*35,
	LowSpeedThresholdInPcsPerHour INTEGER DEFAULT -1, --do not apply
    AutomaticallyIdentifyChangeovers BOOLEAN DEFAULT true,
    LanguageCode INTEGER DEFAULT 1, -- english
	AvailabilityLossStates INTEGER[] DEFAULT '{40000, 180000, 190000, 200000, 210000, 220000}', 
    PerformanceLossStates INTEGER[] DEFAULT '{20000, 50000, 60000, 70000, 80000, 90000, 100000, 110000, 120000, 130000, 140000, 150000}'
)