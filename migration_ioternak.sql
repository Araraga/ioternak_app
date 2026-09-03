-- ================================================
-- IoTernak Database Migration
-- Jalankan sekali di PostgreSQL server backend Anda
-- ================================================

-- 1. Fix barn_id FK pada tabel devices (jika belum ada)
ALTER TABLE public.devices ADD COLUMN IF NOT EXISTS barn_id int4 NULL;
ALTER TABLE public.devices DROP CONSTRAINT IF EXISTS devices_barn_id_fkey;
ALTER TABLE public.devices
  ADD CONSTRAINT devices_barn_id_fkey
  FOREIGN KEY (barn_id) REFERENCES public.barns(id) ON DELETE SET NULL;

-- 2. Tabel catatan keuangan kandang
CREATE TABLE IF NOT EXISTS public.barn_finances (
  id          SERIAL        PRIMARY KEY,
  barn_id     INT4          REFERENCES public.barns(id)       ON DELETE CASCADE,
  user_id     INT4          REFERENCES public.users(user_id)  ON DELETE CASCADE,
  category    VARCHAR(100)  NOT NULL DEFAULT 'lainnya',
  amount      NUMERIC(12,2) NOT NULL,
  description TEXT,
  recorded_at TIMESTAMP     DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_barn_finances_barn ON public.barn_finances(barn_id);
CREATE INDEX IF NOT EXISTS idx_barn_finances_user ON public.barn_finances(user_id);

-- 3. Tabel catatan pakan harian
--    (total_cost dihitung di aplikasi, bukan GENERATED ALWAYS, agar kolom nullable aman)
CREATE TABLE IF NOT EXISTS public.barn_feed_logs (
  id           SERIAL        PRIMARY KEY,
  barn_id      INT4          REFERENCES public.barns(id)          ON DELETE CASCADE,
  user_id      INT4          REFERENCES public.users(user_id)     ON DELETE CASCADE,
  device_id    VARCHAR(100)  REFERENCES public.devices(device_id) ON DELETE SET NULL,
  feed_type    VARCHAR(100),
  quantity_kg  NUMERIC(8,2),
  cost_per_kg  NUMERIC(10,2),
  total_cost   NUMERIC(12,2),
  notes        TEXT,
  feeding_time TIME,
  status       VARCHAR(20)   DEFAULT 'selesai',
  logged_at    TIMESTAMP     DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_barn_feed_logs_barn ON public.barn_feed_logs(barn_id);

-- 4. Tabel notifikasi in-app
CREATE TABLE IF NOT EXISTS public.notifications (
  id         SERIAL        PRIMARY KEY,
  user_id    INT4          REFERENCES public.users(user_id)     ON DELETE CASCADE,
  device_id  VARCHAR(100)  REFERENCES public.devices(device_id) ON DELETE SET NULL,
  barn_id    INT4          REFERENCES public.barns(id)          ON DELETE SET NULL,
  type       VARCHAR(50)   DEFAULT 'system',
  title      VARCHAR(255)  NOT NULL,
  body       TEXT,
  is_read    BOOLEAN       DEFAULT FALSE,
  created_at TIMESTAMP     DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user   ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id, is_read);
