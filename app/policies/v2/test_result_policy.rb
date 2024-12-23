# frozen_string_literal: true

module V2
  # Policies for accessing Test Results
  class TestResultPolicy < V2::ApplicationPolicy
    def index?
      true # FIXME: this is handled in scoping
    end

    def show?
      match_account? && match_group?
    end

    def os_versions?
      true
    end

    def security_guide_versions?
      true
    end

    private

    def match_account?
      record.system.org_id == user.org_id
    end

    def match_group?
      groups = user.inventory_groups
      system = record.system
      # Global access || ungrouped host || group matching
      (groups == Rbac::ANY) || (system.groups.blank? && groups&.include?([])) || system.group_ids.intersect?(groups)
    end

    # Only show test results in our user account
    class Scope < V2::ApplicationPolicy::Scope
      def resolve
        groups = user.inventory_groups

        return scope.none if user.org_id.blank? || groups.blank?

        groups == Rbac::ANY ? base_scope : base_scope.with_groups(groups, V2::System.arel_table.alias(:system))
      end

      def base_scope
        # Make sure that the `system` reflection is joined to the scope before applying the WHERE clause
        with_system = scope.try(:joins_values).try(:include?, :system) ? scope : scope.joins(:system)
        with_system.where(system: { org_id: user.org_id })
      end
    end
  end
end
