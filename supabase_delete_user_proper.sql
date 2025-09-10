-- Create a proper RPC function to delete a user account
-- This function will delete the user from auth.users table
-- Note: This requires the function to be created by a superuser or admin

-- First, create the function that can delete from auth.users
CREATE OR REPLACE FUNCTION public.delete_user_account(user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Delete all shoots owned by the user
  DELETE FROM public."Shoot" WHERE "userId" = user_id;
  
  -- Delete all media assets owned by the user  
  DELETE FROM public.media_assets WHERE user_id = user_id;
  
  -- Delete all files in the user's private folder in Storage
  DELETE FROM storage.objects WHERE bucket_id = 'user_files' AND owner = user_id;
  
  -- Delete the user from auth.users table
  -- This is the critical part that actually deletes the user account
  DELETE FROM auth.users WHERE id = user_id;
  
  RAISE NOTICE 'User % and all associated data deleted successfully', user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user_account(UUID) TO authenticated;

-- Alternative approach: Create a function that just deletes from auth.users
-- This might work better if the above doesn't have permission
CREATE OR REPLACE FUNCTION public.delete_user_auth_only(user_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Delete the user from auth.users table
  DELETE FROM auth.users WHERE id = user_id;
  
  RAISE NOTICE 'User % deleted from auth.users', user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user_auth_only(UUID) TO authenticated;
