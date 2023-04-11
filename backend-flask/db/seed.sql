-- this file was manually created
INSERT INTO public.users (display_name,email, handle, cognito_user_id)
VALUES
  ('Jay Gathu','jjgathu17@gmail.com','Jay' ,'MOCK'),
  ('Jerry Gathu','jerrycloud67@gmail.com','Jerry' ,'MOCK'),
  ('Londo Molari','lmolari@centari.co','mlari','MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'Jerry' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )