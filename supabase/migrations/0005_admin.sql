-- PitWall — admin yetkisi + joker_questions yazma RLS'i

alter table public.profiles add column is_admin boolean not null default false;

-- Admin'ler joker sorularını yazabilir.
create policy "joker_admin_insert" on public.joker_questions for insert
  with check (exists (
    select 1 from public.profiles where id = auth.uid() and is_admin
  ));
create policy "joker_admin_update" on public.joker_questions for update
  using (exists (
    select 1 from public.profiles where id = auth.uid() and is_admin
  ));
create policy "joker_admin_delete" on public.joker_questions for delete
  using (exists (
    select 1 from public.profiles where id = auth.uid() and is_admin
  ));

-- Helper: kullanıcı admin mi? (Flutter route guard'ı için)
create or replace function public.is_current_user_admin()
returns boolean language sql security definer set search_path = public stable as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;
grant execute on function public.is_current_user_admin() to authenticated;
