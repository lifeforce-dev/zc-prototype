"""
This module provides an API for resolving module dependencies. Modules, such as in SFML
might depend on eachother. Including a module with dependencies forces including
those dependencies. With this helper we can determine which dependencies are required.
"""


from dataclasses import dataclass, field
from collections import defaultdict

@dataclass
class ModuleState:
    name: str = ""
    is_enabled: bool = True
    is_checked: bool = False
    dependencies: list[str] = field(default_factory=list)
    module_id: int = 0


class ModuleDependencyHelper:
    def __init__(self, module_states: list[ModuleState]):
        self.modules: dict[str, ModuleState] = {}
        self.module_dependents: defaultdict[str, list[str]] = defaultdict(list)
        self.is_initialized: bool = False

        self._add_modules(module_states)
        self.__init()

    def set_module_id_for_name(self, module_name: str, module_id: int):
        if module_name not in self.modules:
            raise AssertionError(f"'{module_name}' not found in modules.")
        self.modules[module_name].module_id = module_id


    def set_module_checked_state_by_name(self, name: str, is_checked: bool):
        """
        Given a module name, sets its state to is_checked and updates the dependency
        graph, making cascading changes to affected dependencies.

        Args:
            name (str): the name of the module to set the checked state of

        Returns:
            None
        """
        self._update_module_state(name, is_checked)



    def get_module_states(self) -> list[ModuleState]:
        """
        Returns the list of all ModuleStates we know about. You'll want to call this
        after adding a module or setting its check_state.

        Returns:
            list[ModuleState]
        """
        if not self.is_initialized:
            raise AssertionError(f"Attempted to use ModuleDependencyHelper before initialization.")

        return list(self.modules.values())


    def _update_module_state(self, name: str, is_checked: bool):
        """
        Private method used to update module dependencies when its state
        has changed.

        Args:
            name (str): The module_state name we will update.
            is_checked (bool): whether the module is checked in the UI or not.
        """
        module_state = self.modules[name]
        module_state.is_checked = is_checked

        for dependency_name in module_state.dependencies:
            if dependency_name not in self.modules:
                raise AssertionError(f"'{dependency_name}' not found in modules.")
            dependency_module_state = self.modules[dependency_name]

            if is_checked:
                # If we check a module with dependencies, those modules are required to be checked.
                dependency_module_state.is_checked = True

                # Ensure that the required dependency cannot be unchecked.
                dependency_module_state.is_enabled = False
            else:
                if self._can_enable_dependency(dependency_name):
                    dependency_module_state.is_enabled = True


    def _can_enable_dependency(self, dependency_name: str) -> bool:
        """
        We're allowed to re-enable a dependency if its not depended on by anything else.

        Args:
            dependency_name (str): The name of the dependency we're checking.
        
        Returns:
            bool indicating whether we can set back to enabled or not.
        """

        assert dependency_name in self.module_dependents, \
             f"'{dependency_name}' not found in module_dependents."

        dependant_names = self.module_dependents[dependency_name]

        for dependent_name in dependant_names:
            if self.modules[dependent_name].is_checked:
                return False

        return True


    def _add_modules(self, module_states: list[ModuleState]):
        """
        Adds all the modules to the dependency graph.
        
        Args:
            module_states (list[ModuleState]): List of module states to add.
        
        Returns:
            None
        """
        for module_state in module_states:
            self._add_module(module_state)


    def _add_module(self, module_state: ModuleState):
        """
        Adds the module to the dependency graph.

        Args:
            module_state (ModuleState): The module and its current state.

        Returns:
            None
        """
        self.modules[module_state.name] = module_state
        for dependency in module_state.dependencies:
            self.module_dependents[dependency].append(module_state.name)


    def __init(self):
        if not self.modules:
            raise AssertionError("Do not call ModuleDependencyHelper with default constructor.")

        for module_name, module_state in self.modules.items():
            self._update_module_state(module_name, module_state.is_checked)
        self.is_initialized = True
