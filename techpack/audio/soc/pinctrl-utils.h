/*
 * Utils functions to implement the pincontrol driver.
 *
 * Mirrors drivers/pinctrl/pinctrl-utils.h so techpack drivers can use
 * the pinctrl utils API without reaching into pinctrl core internals.
 */

#ifndef __PINCTRL_UTILS_H__
#define __PINCTRL_UTILS_H__

int pinctrl_utils_reserve_map(struct pinctrl_dev *pctldev,
		struct pinctrl_map **map, unsigned *reserved_maps,
		unsigned *num_maps, unsigned reserve);
int pinctrl_utils_add_map_mux(struct pinctrl_dev *pctldev,
		struct pinctrl_map **map, unsigned *reserved_maps,
		unsigned *num_maps, const char *group,
		const char *function);
int pinctrl_utils_add_map_configs(struct pinctrl_dev *pctldev,
		struct pinctrl_map **map, unsigned *reserved_maps,
		unsigned *num_maps, const char *group,
		unsigned long *configs, unsigned num_configs,
		enum pinctrl_map_type type);
int pinctrl_utils_add_config(struct pinctrl_dev *pctldev,
		unsigned long **configs, unsigned *num_configs,
		unsigned long config);
void pinctrl_utils_free_map(struct pinctrl_dev *pctldev,
		struct pinctrl_map *map, unsigned num_maps);

#endif /* __PINCTRL_UTILS_H__ */
