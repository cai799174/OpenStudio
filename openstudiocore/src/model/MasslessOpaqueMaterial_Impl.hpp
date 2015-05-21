/**********************************************************************
 *  Copyright (c) 2008-2015, Alliance for Sustainable Energy.
 *  All rights reserved.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 **********************************************************************/

#ifndef MODEL_MASSLESSOPAQUEMATERIAL_IMPL_HPP
#define MODEL_MASSLESSOPAQUEMATERIAL_IMPL_HPP

#include "ModelAPI.hpp"
#include "OpaqueMaterial_Impl.hpp"

#include "../utilities/units/Quantity.hpp"
#include "../utilities/units/OSOptionalQuantity.hpp"

namespace openstudio {
namespace model {

namespace detail {

  /** MasslessOpaqueMaterial_Impl is a OpaqueMaterial_Impl that is the implementation class for MasslessOpaqueMaterial.*/
  class MODEL_API MasslessOpaqueMaterial_Impl : public OpaqueMaterial_Impl {
    Q_OBJECT;

    Q_PROPERTY(std::string roughness READ roughness WRITE setRoughness);
    Q_PROPERTY(std::vector<std::string> roughnessValues READ roughnessValues);

    Q_PROPERTY(double thermalResistance READ thermalResistance WRITE setThermalResistance);
    Q_PROPERTY(openstudio::Quantity thermalResistance_SI READ thermalResistance_SI WRITE setThermalResistance);
    Q_PROPERTY(openstudio::Quantity thermalResistance_IP READ thermalResistance_IP WRITE setThermalResistance);

    Q_PROPERTY(double thermalAbsorptance READ thermalAbsorptance WRITE setThermalAbsorptance RESET resetThermalAbsorptance);
    Q_PROPERTY(openstudio::Quantity thermalAbsorptance_SI READ thermalAbsorptance_SI WRITE setThermalAbsorptance RESET resetThermalAbsorptance);
    Q_PROPERTY(openstudio::Quantity thermalAbsorptance_IP READ thermalAbsorptance_IP WRITE setThermalAbsorptance RESET resetThermalAbsorptance);
    Q_PROPERTY(bool isThermalAbsorptanceDefaulted READ isThermalAbsorptanceDefaulted);

    Q_PROPERTY(double solarAbsorptance READ solarAbsorptance WRITE setSolarAbsorptance RESET resetSolarAbsorptance);
    Q_PROPERTY(openstudio::Quantity solarAbsorptance_SI READ solarAbsorptance_SI WRITE setSolarAbsorptance RESET resetSolarAbsorptance);
    Q_PROPERTY(openstudio::Quantity solarAbsorptance_IP READ solarAbsorptance_IP WRITE setSolarAbsorptance RESET resetSolarAbsorptance);
    Q_PROPERTY(bool isSolarAbsorptanceDefaulted READ isSolarAbsorptanceDefaulted);

    Q_PROPERTY(double visibleAbsorptance READ visibleAbsorptance WRITE setVisibleAbsorptance RESET resetVisibleAbsorptance);
    Q_PROPERTY(openstudio::Quantity visibleAbsorptance_SI READ visibleAbsorptance_SI WRITE setVisibleAbsorptance RESET resetVisibleAbsorptance);
    Q_PROPERTY(openstudio::Quantity visibleAbsorptance_IP READ visibleAbsorptance_IP WRITE setVisibleAbsorptance RESET resetVisibleAbsorptance);
    Q_PROPERTY(bool isVisibleAbsorptanceDefaulted READ isVisibleAbsorptanceDefaulted);

    Q_PROPERTY(double conductivity READ conductivity WRITE setConductivity);
    Q_PROPERTY(openstudio::Quantity conductivity_SI READ conductivity_SI WRITE setConductivity);
    Q_PROPERTY(openstudio::Quantity conductivity_IP READ conductivity_IP WRITE setConductivity);

    Q_PROPERTY(double density READ density WRITE setDensity);
    Q_PROPERTY(openstudio::Quantity density_SI READ density_SI WRITE setDensity);
    Q_PROPERTY(openstudio::Quantity density_IP READ density_IP WRITE setDensity);

    Q_PROPERTY(double specificHeat READ specificHeat WRITE setSpecificHeat);
    Q_PROPERTY(openstudio::Quantity specificHeat_SI READ specificHeat_SI WRITE setSpecificHeat);
    Q_PROPERTY(openstudio::Quantity specificHeat_IP READ specificHeat_IP WRITE setSpecificHeat);

    // TODO: Add relationships for objects related to this one, but not pointed to by the underlying data.
    //       Such relationships can be generated by the GenerateRelationships.rb script.
   public:
    /** @name Constructors and Destructors */
    //@{

    MasslessOpaqueMaterial_Impl(const IdfObject& idfObject,
                                Model_Impl* model,
                                bool keepHandle);

    MasslessOpaqueMaterial_Impl(const openstudio::detail::WorkspaceObject_Impl& other,
                                Model_Impl* model,
                                bool keepHandle);

    MasslessOpaqueMaterial_Impl(const MasslessOpaqueMaterial_Impl& other,
                                Model_Impl* model,
                                bool keepHandle);

    virtual ~MasslessOpaqueMaterial_Impl() {}

    //@}

    /** @name Virtual Methods */
    //@{

    virtual const std::vector<std::string>& outputVariableNames() const override;

    virtual IddObjectType iddObjectType() const override;

    //@}
    /** @name Getters */
    //@{

    std::string roughness() const;

    /** The conductivitiy of the material in W/m*K. */
    virtual double thermalConductivity() const override;

    /** The conductance of the material in W/m^2*K. */
    virtual double thermalConductance() const override;

    /** The resistivity of the material in m*K/W. */
    virtual double thermalResistivity() const override;

    /** The resistance of the material in m^2*K/W. */
    virtual double thermalResistance() const override;

    virtual double thermalAbsorptance() const override;

    virtual boost::optional<double> thermalReflectance() const override;

    virtual double solarAbsorptance() const override;

    virtual boost::optional<double> solarReflectance() const override;

    virtual double visibleAbsorptance() const override;

    virtual boost::optional<double> visibleReflectance() const override;

    Quantity getThermalResistance(bool returnIP=false) const;

    Quantity getThermalAbsorptance(bool returnIP=false) const;

    bool isThermalAbsorptanceDefaulted() const;

    Quantity getSolarAbsorptance(bool returnIP=false) const;

    bool isSolarAbsorptanceDefaulted() const;

    Quantity getVisibleAbsorptance(bool returnIP=false) const;

    bool isVisibleAbsorptanceDefaulted() const;

    double conductivity() const;

    Quantity getConductivity(bool returnIP=false) const;

    double density() const;

    Quantity getDensity(bool returnIP=false) const;

    double specificHeat() const;

    Quantity getSpecificHeat(bool returnIP=false) const;

    //@}
    /** @name Setters */
    //@{

    bool setRoughness(std::string roughness);

    /** Set thickness to value (m). */
    virtual bool setThickness(double value) override;

    /** Sets the conductivity of the material in W/m*K, if possible. */
    virtual bool setThermalConductivity(double value) override;

    /** Sets the conductance of the material in W/m^2*K, if possible. */
    virtual bool setThermalConductance(double value) override;

    /** Sets the resistivity of the material in m*K/W, if possible. */
    virtual bool setThermalResistivity(double value) override;

    /** Sets the resistance of the material in m^2*K/W, if possible. */
    virtual bool setThermalResistance(double value) override;

    virtual bool setThermalAbsorptance(boost::optional<double> value);

    virtual bool setThermalReflectance(boost::optional<double> value) override;

    virtual bool setSolarAbsorptance(boost::optional<double> value) override;

    virtual bool setSolarReflectance(boost::optional<double> value) override;

    virtual bool setVisibleAbsorptance(boost::optional<double> value) override;

    virtual bool setVisibleReflectance(boost::optional<double> value) override;

    bool setThermalResistance(const Quantity& thermalResistance);

    bool setThermalAbsorptance(double thermalAbsorptance) override;

    bool setThermalAbsorptance(const Quantity& thermalAbsorptance);

    void resetThermalAbsorptance();

    bool setSolarAbsorptance(double solarAbsorptance);

    bool setSolarAbsorptance(const Quantity& solarAbsorptance);

    void resetSolarAbsorptance();

    bool setVisibleAbsorptance(double visibleAbsorptance);

    bool setVisibleAbsorptance(const Quantity& visibleAbsorptance);

    void resetVisibleAbsorptance();

    bool setConductivity(double conductivity);

    bool setConductivity(const Quantity& conductivity);

    bool setDensity(double density);

    bool setDensity(const Quantity& density);

    bool setSpecificHeat(double specificHeat);

    bool setSpecificHeat(const Quantity& specificHeat);

    //@}
    /** @name Other */
    //@{

    //@}
   protected:
   private:
    REGISTER_LOGGER("openstudio.model.MasslessOpaqueMaterial");

    std::vector<std::string> roughnessValues() const;
    openstudio::Quantity thermalResistance_SI() const;
    openstudio::Quantity thermalResistance_IP() const;
    openstudio::Quantity thermalAbsorptance_SI() const;
    openstudio::Quantity thermalAbsorptance_IP() const;
    openstudio::Quantity solarAbsorptance_SI() const;
    openstudio::Quantity solarAbsorptance_IP() const;
    openstudio::Quantity visibleAbsorptance_SI() const;
    openstudio::Quantity visibleAbsorptance_IP() const;
    openstudio::Quantity conductivity_SI() const;
    openstudio::Quantity conductivity_IP() const;
    openstudio::Quantity density_SI() const;
    openstudio::Quantity density_IP() const;
    openstudio::Quantity specificHeat_SI() const;
    openstudio::Quantity specificHeat_IP() const;

  };

} // detail

} // model
} // openstudio

#endif // MODEL_MASSLESSOPAQUEMATERIAL_IMPL_HPP

