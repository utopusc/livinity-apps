DELETE FROM apps
WHERE manifest->>'importSource' IN ('coolify@e7dff30', 'caprover@bd357c9')
  AND verified = false;
