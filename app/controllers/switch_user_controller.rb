class SwitchUserController < ApplicationController
  # use :before_action instead of deprecated before_filter
  if respond_to? :before_action
    before_action :developer_modes_only, :switch_back
  else
    before_filter :developer_modes_only, :switch_back
  end

  def set_current_user
    handle_request(params)

    redirect_to(SwitchUser.redirect_path.call(request, params))
  end

  def remember_user
    redirect_to(SwitchUser.redirect_path.call(request, params))
  end

  private

  def switch_back
    if SwitchUser.switch_back
      provider.remember_current_user(true) if params[:remember] == "true"
      provider.remember_current_user(false) if params[:remember] == "false"
    end
  end

  def developer_modes_only
    raise ActionController::RoutingError.new('Do not try to hack us.') unless available?
  end

  def available?
    SwitchUser.guard_class.new(self, provider).controller_available?
  end

  def handle_request(params)
    if params[:scope_identifier].blank?
      provider.logout_all
    else
      record = SwitchUser.data_sources.find_scope_id(params[:scope_identifier])
      unless record
        provider.logout_all
        return
      end
      if SwitchUser.login_exclusive
        provider.login_exclusive(record.user, scope: record.scope)
      else
        provider.login_inclusive(record.user, scope: record.scope)
      end
    end
  end

  # TODO make helper methods, so this can be eliminated from the
  # SwitchUserHelper
  def provider
    SwitchUser::Provider.init(self)
  end
end
