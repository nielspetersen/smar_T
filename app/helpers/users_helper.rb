module UsersHelper

  def localized_role_as_string(user)
    case user.role
      when 'superadmin'
        t('users.roles.superadmin')
      when 'admin'
        t('users.roles.admin')
      when 'planer'
        t('users.roles.planer')
      else
        t('users.roles.driver')
    end
  end
end