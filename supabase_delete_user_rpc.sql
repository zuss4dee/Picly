-- Create RPC function to delete user account
-- This function will be called from the app to delete a user
CREATE OR REPLACE FUNCTION public.delete_user_account(user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Delete all shoots owned by the user
  DELETE FROM public."Shoot" WHERE "userId" = user_id;
  
  -- Delete all media assets owned by the user
  DELETE FROM public.media_assets WHERE user_id = user_id;
  
  -- Delete all files in the user's private folder in Storage
  DELETE FROM storage.objects WHERE bucket_id = 'user_files' AND owner = user_id;
  
  -- Finally, delete the user from auth.users
  -- This will trigger the handle_user_delete function as a backup
  DELETE FROM auth.users WHERE id = user_id;
  
  RAISE NOTICE 'User % and all associated data deleted successfully', user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user_account(UUID) TO authenticated;

-- Also create a simpler function that just deletes from auth.users
-- This will trigger the existing handle_user_delete trigger
CREATE OR REPLACE FUNCTION public.delete_user_auth_only(user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Delete the user from auth.users
  -- This will trigger the handle_user_delete function
  DELETE FROM auth.users WHERE id = user_id;
  
  RAISE NOTICE 'User % deleted from auth.users, trigger should clean up data', user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user_auth_only(UUID) TO authenticated;
