create table if not exists categories (
  name text primary key,
  created_at timestamptz not null default now()
);

create table if not exists movements (
  id text primary key,
  category text not null,
  amount numeric(12,2) not null check (amount > 0),
  type text not null check (type in ('expense','income')),
  date date not null,
  created_at bigint not null
);

create table if not exists credit_cards (
  id text primary key,
  name text not null,
  total_debt numeric(12,2) not null default 0,
  cut_day int not null check (cut_day between 1 and 31),
  due_day int not null check (due_day between 1 and 31),
  min_percent numeric(5,2) not null default 5,
  min_payment numeric(12,2),
  payment_amount numeric(12,2),
  created_at timestamptz not null default now()
);

alter table categories enable row level security;
alter table movements enable row level security;
alter table credit_cards enable row level security;

create policy "anon full access" on categories for all to anon using (true) with check (true);
create policy "anon full access" on movements for all to anon using (true) with check (true);
create policy "anon full access" on credit_cards for all to anon using (true) with check (true);

insert into categories (name) values
  ('Comida'), ('Transporte'), ('Renta'), ('Entretenimiento'), ('Salud'), ('Otros')
on conflict (name) do nothing;
